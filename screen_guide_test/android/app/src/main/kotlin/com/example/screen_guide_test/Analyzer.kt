package com.example.screen_guide_test

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import com.example.screen_guide_test.logic.*
import com.google.mlkit.nl.entityextraction.Entity
import com.google.mlkit.nl.entityextraction.EntityExtraction
import com.google.mlkit.nl.entityextraction.EntityExtractionParams
import com.google.mlkit.nl.entityextraction.EntityExtractorOptions
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import java.io.File

// 보고서 4.5~4.7: ML Kit OCR(F02) → 후처리 로직 → 개인정보 후보(F03, 정규식 + ML Kit 개체 추출)
class Analyzer(private val context: Context) {
    private val tag = "ScreenGuide"
    private val recognizer = TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build())
    private val extractor = EntityExtraction.getClient(
        EntityExtractorOptions.Builder(EntityExtractorOptions.KOREAN).build())
    private val main = Handler(Looper.getMainLooper())

    fun analyze(path: String, selector: String, onDone: (Map<String, Any?>) -> Unit, onError: (String) -> Unit) {
        val t0 = SystemClock.elapsedRealtime()
        val image = try { InputImage.fromFilePath(context, Uri.fromFile(File(path))) }
                    catch (e: Exception) { onError("image_read_failed"); return }

        recognizer.process(image)
            .addOnSuccessListener { text ->
                val tOcr = SystemClock.elapsedRealtime() - t0
                val lines = text.textBlocks.flatMap { it.lines }.map { l ->
                    OcrLine(l.text, l.boundingBox?.let { Box(it.left, it.top, it.right, it.bottom) }) }
                val elements = toUiElements(lines)
                val screen = identifyScreen(elements, SAMPLE_MAPS)
                val target = findTarget(elements, selector)
                val fullText = elements.joinToString("\n") { it.label }
                val regex = regexCandidates(fullText)

                Log.i(tag, "OCR ${tOcr}ms, lines=${elements.size}, screen=${screen?.screenId}, target=${target?.label}")
                elements.forEach { Log.i(tag, "  [${it.box.left},${it.box.top},${it.box.right},${it.box.bottom}] ${it.label}") }

                runEntityExtraction(fullText) { mlkit, status ->
                    val merged = merge(regex + mlkit, fullText).sortedBy { it.start }
                    val total = SystemClock.elapsedRealtime() - t0
                    Log.i(tag, "privacy=${merged.size} (entity: $status), total ${total}ms")
                    merged.forEach { Log.i(tag, "  ${it.types.joinToString("+")} : ${mask(fullText.substring(it.start, it.end))}") }
                    onDone(mapOf(
                        "imageWidth" to image.width, "imageHeight" to image.height,
                        "ocrMs" to tOcr, "totalMs" to total,
                        "screenId" to screen?.screenId, "selector" to selector, "target" to target?.label,
                        "elements" to elements.map { mapOf("label" to it.label, "l" to it.box.left, "t" to it.box.top,
                            "r" to it.box.right, "b" to it.box.bottom, "isTarget" to (it == target)) },
                        "privacy" to merged.map { mapOf("types" to it.types.joinToString("+"),
                            "masked" to mask(fullText.substring(it.start, it.end))) },
                        "entityStatus" to status,
                    ))
                }
            }
            .addOnFailureListener { onError("analysis_failed") }   // 명세서 6.2 예외 동작
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
