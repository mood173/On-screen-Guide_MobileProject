package com.screenguide.screen_guide

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import com.screenguide.screen_guide.logic.*
import com.google.mlkit.common.model.RemoteModelManager
import com.google.mlkit.nl.entityextraction.Entity
import com.google.mlkit.nl.entityextraction.EntityExtraction
import com.google.mlkit.nl.entityextraction.EntityExtractionParams
import com.google.mlkit.nl.entityextraction.EntityExtractionRemoteModel
import com.google.mlkit.nl.entityextraction.EntityExtractorOptions
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

// 보고서 4.5~4.7: ML Kit OCR(F02) → 후처리 로직 → 개인정보 후보(F03, 정규식 + ML Kit 개체 추출)
// 응답은 항상 ChannelCodec 의 계약 형식 Map 하나다 (성공이든 실패든).
class Analyzer(private val context: Context) {
    private val tag = "ScreenGuide"
    private val recognizer = TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build())
    private val extractor = EntityExtraction.getClient(
        EntityExtractorOptions.Builder(EntityExtractorOptions.KOREAN).build())
    private val main = Handler(Looper.getMainLooper())
    private val modelManager = RemoteModelManager.getInstance()
    private val entityModel = EntityExtractionRemoteModel.Builder(EntityExtractorOptions.KOREAN).build()
    private val downloading = AtomicBoolean(false)

    companion object {
        // 모델이 있을 때 개체 추출을 기다리는 최대 시간. 기기에서 측정 전이라 어림값이다 (3초 목표 안).
        private const val ANNOTATE_LIMIT_MS = 1500L
    }

    fun analyze(req: AnalyzeRequest, onDone: (Map<String, Any?>) -> Unit) {
        val t0 = SystemClock.elapsedRealtime()
        val image = try { InputImage.fromFilePath(context, Uri.fromFile(File(req.imagePath))) }
                    catch (e: Exception) { onDone(ChannelCodec.error(req.requestId, ChannelCodec.IMAGE_READ_FAILED)); return }

        val failed = { onDone(ChannelCodec.error(req.requestId, ChannelCodec.ANALYSIS_FAILED)) }
        recognizer.process(image)
            .addOnSuccessListener { text -> try {
                val tOcr = SystemClock.elapsedRealtime() - t0
                val lines = text.textBlocks.flatMap { it.lines }.map { l ->
                    OcrLine(l.text, l.boundingBox?.let { Box(it.left, it.top, it.right, it.bottom) }) }
                val elements = toUiElements(lines)
                val screen = identifyScreen(elements, req.screens)
                val target = req.selector?.let { findTarget(elements, it) }
                val fullText = joinLabels(elements)

                // 로그에는 줄 수와 시간만 남긴다. 인식한 글자·가린 값·상자 좌표는 찍지 않는다 (K10, 협업규격_최종 3.3)
                Log.i(tag, "ocr ${tOcr}ms, lines=${elements.size}")

                runEntityExtraction(fullText) { mlkit, mlkitOk -> try {
                    val pii = piiHits(elements, mlkit)
                    val total = SystemClock.elapsedRealtime() - t0
                    Log.i(tag, "total ${total}ms")
                    onDone(ChannelCodec.encode(AnalyzeResult(
                        requestId = req.requestId, width = image.width, height = image.height,
                        screenId = screen?.screenId,
                        elements = elements,
                        target = target,
                        pii = pii, regexOk = true, mlkitOk = mlkitOk,
                        ocrMs = tOcr, totalMs = total,
                    )))
                } catch (e: Exception) { failed() } }
            } catch (e: Exception) { failed() } }
            .addOnFailureListener { failed() }   // 명세서 6.2 예외 동작
    }

    // ML Kit 개체 추출. 모델이 없거나(오프라인 첫 실행) 실패하면 정규식 결과만 쓴다.
    // ML Kit 개체 추출 (N1). 모델이 내려받아져 있는지 먼저 확인한다.
    // - 없으면 내려받기만 뒤에서 시작하고(한 번만) 이번 분석은 기다리지 않고 정규식만 쓴다 → mlkit: failed
    // - 있으면 추출하되 ANNOTATE_LIMIT_MS 안에 끝나지 않으면 failed
    // done(후보, ok 여부): ok가 아니면(모델 없음·확인 실패·시간 초과·추출 실패) 모두 failed (K9)
    private fun runEntityExtraction(text: String, done: (List<Candidate>, Boolean) -> Unit) {
        var finished = false
        fun finish(c: List<Candidate>, ok: Boolean) { if (!finished) { finished = true; done(c, ok) } }

        modelManager.isModelDownloaded(entityModel)
            .addOnSuccessListener { downloaded ->
                if (downloaded != true) { startModelDownload(); finish(emptyList(), false); return@addOnSuccessListener }
                main.postDelayed({ finish(emptyList(), false) }, ANNOTATE_LIMIT_MS)
                val params = EntityExtractionParams.Builder(text)
                    .setEntityTypesFilter(setOf(Entity.TYPE_PHONE, Entity.TYPE_EMAIL, Entity.TYPE_ADDRESS,
                        Entity.TYPE_PAYMENT_CARD, Entity.TYPE_URL))
                    .build()
                extractor.annotate(params)
                    .addOnSuccessListener { list ->
                        finish(list.flatMap { a -> a.entities.mapNotNull { e ->
                            typeName(e.type)?.let { Candidate(a.start, a.end, it) } } }, true)
                    }
                    .addOnFailureListener { finish(emptyList(), false) }
            }
            .addOnFailureListener { finish(emptyList(), false) }
    }

    // 다음 분석부터 쓰도록 뒤에서 내려받는다. 결과를 기다리지 않는다. 실패하면 다음 분석 때 다시 시도한다.
    private fun startModelDownload() {
        if (!downloading.compareAndSet(false, true)) return
        extractor.downloadModelIfNeeded()
            .addOnCompleteListener { t ->
                downloading.set(false)
                Log.i(tag, "entity model download ${if (t.isSuccessful) "done" else "failed"}")
            }
    }

    // R5: 엔진 이름을 붙이지 않는다. 9개 밖의 유형은 버린다.
    private fun typeName(t: Int): String? = when (t) {
        Entity.TYPE_PHONE -> "전화"; Entity.TYPE_EMAIL -> "이메일"
        Entity.TYPE_ADDRESS -> "주소"; Entity.TYPE_PAYMENT_CARD -> "카드"
        Entity.TYPE_URL -> "URL"; else -> null
    }
}
