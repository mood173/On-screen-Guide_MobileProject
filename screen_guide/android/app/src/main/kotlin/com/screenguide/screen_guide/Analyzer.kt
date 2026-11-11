package com.screenguide.screen_guide

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import com.screenguide.screen_guide.logic.*
import com.google.mlkit.nl.entityextraction.Entity
import com.google.mlkit.nl.entityextraction.EntityExtraction
import com.google.mlkit.nl.entityextraction.EntityExtractionParams
import com.google.mlkit.nl.entityextraction.EntityExtractorOptions
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import java.io.File

// 보고서 4.5~4.7: ML Kit OCR(F02) → 후처리 로직 → 개인정보 후보(F03, 정규식 + ML Kit 개체 추출)
// 응답은 항상 ChannelCodec 의 계약 형식 Map 하나다 (성공이든 실패든).
class Analyzer(private val context: Context) {
    private val tag = "ScreenGuide"
    private val recognizer = TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build())
    private val extractor = EntityExtraction.getClient(
        EntityExtractorOptions.Builder(EntityExtractorOptions.KOREAN).build())
    private val main = Handler(Looper.getMainLooper())

    fun analyze(req: AnalyzeRequest, onDone: (Map<String, Any?>) -> Unit) {
        val t0 = SystemClock.elapsedRealtime()
        val image = try { InputImage.fromFilePath(context, Uri.fromFile(File(req.imagePath))) }
                    catch (e: Exception) { onDone(ChannelCodec.error(req.requestId, ChannelCodec.IMAGE_READ_FAILED)); return }

        recognizer.process(image)
            .addOnSuccessListener { text ->
                val tOcr = SystemClock.elapsedRealtime() - t0
                val lines = text.textBlocks.flatMap { it.lines }.map { l ->
                    OcrLine(l.text, l.boundingBox?.let { Box(it.left, it.top, it.right, it.bottom) }) }
                val elements = toUiElements(lines)
                val screen = identifyScreen(elements, req.screens)
                val target = req.selector?.let { findTarget(elements, it) }
                val fullText = elements.joinToString("\n") { it.label }

                Log.i(tag, "OCR ${tOcr}ms, lines=${elements.size}, screen=${screen?.screenId}, target=${target?.match}")
                elements.forEach { Log.i(tag, "  [${it.box.left},${it.box.top},${it.box.right},${it.box.bottom}] ${it.label}") }

                runEntityExtraction(fullText) { mlkit, status ->
                    val merged = merge(regexCandidates(fullText) + mlkit, fullText).sortedBy { it.start }
                    val starts = elements.runningFold(0) { acc, e -> acc + e.label.length + 1 }
                    val pii = merged.map { c ->
                        val idx = starts.indexOfLast { it <= c.start }.coerceIn(0, elements.lastIndex)
                        PiiHit(c.types.first(), mask(fullText.substring(c.start, c.end)), idx)
                    }
                    val total = SystemClock.elapsedRealtime() - t0
                    Log.i(tag, "privacy=${merged.size} (entity: $status), total ${total}ms")
                    onDone(ChannelCodec.encode(AnalyzeResult(
                        requestId = req.requestId, width = image.width, height = image.height,
                        screenId = screen?.screenId,
                        elements = elements,
                        target = target,
                        pii = pii, regexOk = true, mlkitOk = status == "ok",
                        ocrMs = tOcr, totalMs = total,
                    )))
                }
            }
            .addOnFailureListener { onDone(ChannelCodec.error(req.requestId, ChannelCodec.ANALYSIS_FAILED)) }   // 명세서 6.2 예외 동작
    }

    // ML Kit 개체 추출. 모델이 없거나(오프라인 첫 실행) 실패하면 정규식 결과만 쓴다.
    private fun runEntityExtraction(text: String, done: (List<Candidate>, String) -> Unit) {
        var finished = false
        fun finish(c: List<Candidate>, s: String) { if (!finished) { finished = true; done(c, s) } }
        main.postDelayed({ finish(emptyList(), "timeout") }, 8000)

        extractor.downloadModelIfNeeded()
            .addOnSuccessListener {
                val params = EntityExtractionParams.Builder(text)
                    .setEntityTypesFilter(setOf(Entity.TYPE_PHONE, Entity.TYPE_EMAIL, Entity.TYPE_ADDRESS,
                        Entity.TYPE_PAYMENT_CARD, Entity.TYPE_URL))
                    .build()
                extractor.annotate(params)
                    .addOnSuccessListener { list ->
                        finish(list.map { a -> Candidate(a.start, a.end, a.entities.map { typeName(it.type) }) }, "ok")
                    }
                    .addOnFailureListener { finish(emptyList(), "annotate_failed") }
            }
            .addOnFailureListener { finish(emptyList(), "model_unavailable") }
    }

    private fun typeName(t: Int) = when (t) {
        Entity.TYPE_PHONE -> "전화(ML Kit)"; Entity.TYPE_EMAIL -> "이메일(ML Kit)"
        Entity.TYPE_ADDRESS -> "주소(ML Kit)"; Entity.TYPE_PAYMENT_CARD -> "카드(ML Kit)"
        Entity.TYPE_URL -> "URL(ML Kit)"; else -> "기타(ML Kit)"
    }
}
