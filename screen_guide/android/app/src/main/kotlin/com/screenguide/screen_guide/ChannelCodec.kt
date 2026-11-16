package com.screenguide.screen_guide

import com.screenguide.screen_guide.logic.Box
import com.screenguide.screen_guide.logic.GuidanceMap
import com.screenguide.screen_guide.logic.PiiHit
import com.screenguide.screen_guide.logic.TargetMatch
import com.screenguide.screen_guide.logic.UiElement

// 채널 screen_guide/analyze 의 요청·응답 형식 (계약 v1 결정 1, 협업규격_최종 3.3, lib/shared/contracts/analysis.dart).
// Android 의존이 없어서 JUnit이 contract_fixtures/analyze/ 예시 파일로 직접 확인한다.

data class AnalyzeRequest(
    val requestId: String,
    val imagePath: String,
    val screens: List<GuidanceMap>,
    val selector: String?,          // 요청에 target이 없으면 null → 대상 찾기를 하지 않는다
)

data class AnalyzeResult(
    val requestId: String,
    val width: Int,
    val height: Int,
    val screenId: String?,
    val elements: List<UiElement>,
    val target: TargetMatch?,
    val pii: List<PiiHit>,
    val regexOk: Boolean,
    val mlkitOk: Boolean,
    val ocrMs: Long,
    val totalMs: Long,
)

object ChannelCodec {
    const val NO_PATH = "NO_PATH"
    const val IMAGE_READ_FAILED = "IMAGE_READ_FAILED"
    const val ANALYSIS_FAILED = "ANALYSIS_FAILED"

    /** 채널이 준 인자를 요청으로 해석한다. 형식이 틀리면(필수 키 누락·타입 불일치·빈 imagePath) null. */
    fun decode(args: Any?): AnalyzeRequest? {
        val m = args as? Map<*, *> ?: return null
        val requestId = m["requestId"] as? String ?: return null
        val imagePath = (m["imagePath"] as? String)?.takeIf { it.isNotBlank() } ?: return null
        val guidance = m["guidance"] as? Map<*, *> ?: return null
        val screens = (guidance["screens"] as? List<*> ?: return null).map { s ->
            val sm = s as? Map<*, *> ?: return null
            val id = sm["screenId"] as? String ?: return null
            val anchors = (sm["anchors"] as? List<*> ?: return null).map { it as? String ?: return null }
            GuidanceMap(id, anchors)
        }
        val selector = when (val t = m["target"]) {
            null -> null
            is Map<*, *> -> t["selector"] as? String ?: return null
            else -> return null
        }
        return AnalyzeRequest(requestId, imagePath, screens, selector)
    }

    /** 형식이 틀린 요청에서도 돌려줄 수 있으면 requestId를 돌려준다. */
    fun requestIdOf(args: Any?): String = ((args as? Map<*, *>)?.get("requestId") as? String) ?: ""

    fun encode(r: AnalyzeResult): Map<String, Any?> = mapOf(
        "requestId" to r.requestId,
        "status" to "ok",
        "errorCode" to null,
        "imageSize" to mapOf("w" to r.width, "h" to r.height),
        "screenId" to r.screenId,
        "elements" to r.elements.map { mapOf("label" to it.label, "box" to box(it.box)) },
        "target" to r.target?.let {
            mapOf("label" to it.element.label, "box" to box(it.element.box), "match" to it.match.wire)
        },
        "pii" to r.pii.map { mapOf("type" to it.type, "masked" to it.masked, "elementIndex" to it.elementIndex) },
        "piiEngine" to mapOf("regex" to status(r.regexOk), "mlkit" to status(r.mlkitOk)),
        "timingMs" to mapOf("ocr" to r.ocrMs, "total" to r.totalMs),
    )

    /** 실패도 예외가 아니라 응답 본문으로 알린다 (response_error.json 모양). */
    fun error(requestId: String, code: String): Map<String, Any?> = mapOf(
        "requestId" to requestId,
        "status" to "error",
        "errorCode" to code,
        "imageSize" to null,
        "screenId" to null,
        "elements" to emptyList<Any>(),
        "target" to null,
        "pii" to emptyList<Any>(),
        "piiEngine" to null,
        "timingMs" to null,
    )

    private fun box(b: Box) = listOf(b.left, b.top, b.right, b.bottom)
    private fun status(ok: Boolean) = if (ok) "ok" else "failed"
}
