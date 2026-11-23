package com.screenguide.screen_guide

import com.google.gson.GsonBuilder
import com.screenguide.screen_guide.logic.*
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

// 채널 형식이 계약 v1과 같은지 기기 없이 확인한다 (제작범위 1-1, A1).
// Flutter 시험(test/shared/contracts/fixtures_test.dart)과 같은 contract_fixtures/analyze/ 파일을 읽는다.
class ChannelCodecTest {
    private val gson = GsonBuilder().serializeNulls().create()

    // Gradle 단위 시험의 작업 폴더는 android/app. 위로 올라가며 contract_fixtures 를 찾는다.
    private val fixtureDir: File = generateSequence(File("").absoluteFile) { it.parentFile }
        .map { File(it, "contract_fixtures/analyze") }.first { it.isDirectory }

    private fun load(name: String): Map<*, *> =
        gson.fromJson(File(fixtureDir, name).readText(Charsets.UTF_8), Map::class.java)

    // Kotlin Map → JSON → 다시 읽기. 숫자 타입(Int/Long/Double)을 예시 파일과 같은 모양으로 맞춘다.
    private fun asJson(m: Map<String, Any?>): Any? = gson.fromJson(gson.toJson(m), Any::class.java)

    private fun request(name: String): AnalyzeRequest =
        ChannelCodec.decode(load(name)) ?: throw AssertionError("$name 를 해석하지 못함")

    private fun elementsOf(fixture: Map<*, *>): List<UiElement> = (fixture["elements"] as List<*>).map {
        val e = it as Map<*, *>
        val b = (e["box"] as List<*>).map { n -> (n as Number).toInt() }
        UiElement(e["label"] as String, Box(b[0], b[1], b[2], b[3]))
    }

    // Analyzer가 OCR 뒤에 하는 일과 같은 순서 (화면 식별 → 대상 찾기 → 개인정보 → 응답).
    // OCR 결과 대신 예시 응답의 elements 를 넣고, 크기·시간·mlkit 상태는 예시 값을 그대로 쓴다.
    private fun respond(req: AnalyzeRequest, fixture: Map<*, *>): Map<String, Any?> {
        val elements = elementsOf(fixture)
        val size = fixture["imageSize"] as Map<*, *>
        val timing = fixture["timingMs"] as Map<*, *>
        val engine = fixture["piiEngine"] as Map<*, *>
        return ChannelCodec.encode(AnalyzeResult(
            requestId = fixture["requestId"] as String,
            width = (size["w"] as Number).toInt(), height = (size["h"] as Number).toInt(),
            screenId = identifyScreen(elements, req.screens)?.screenId,
            elements = elements,
            target = req.selector?.let { findTarget(elements, it) },
            pii = piiHits(elements),
            regexOk = engine["regex"] == "ok", mlkitOk = engine["mlkit"] == "ok",
            ocrMs = (timing["ocr"] as Number).toLong(), totalMs = (timing["total"] as Number).toLong(),
        ))
    }

    // 값 대신 JSON 타입만 남긴 모양. 목록은 원소 모양들의 목록.
    private fun shape(x: Any?): Any = when (x) {
        null -> "null"
        is Map<*, *> -> x.entries.associate { (k, v) -> k.toString() to shape(v) }
        is List<*> -> x.map { shape(it) }
        is Number -> "number"
        is String -> "string"
        is Boolean -> "boolean"
        else -> x.javaClass.name
    }

    // 예시 응답 파일 → 그 응답을 만들 요청
    private val cases = mapOf(
        "response_ok.json" to "request_step.json",
        "response_pii.json" to "request_first.json",
        "response_unknown_screen.json" to "request_first.json",
        "response_target_duplicate.json" to "request_step.json",
        "response_target_fuzzy.json" to "request_step.json",
    )

    // ---------- 요청 해석 ----------

    @Test fun 요청_예시_2종을_해석한다() {
        val first = request("request_first.json")
        assertEquals("r1", first.requestId)
        assertTrue(first.imagePath.endsWith("sample_settings.png"))
        assertEquals(listOf("demo.settings", "demo.chat"), first.screens.map { it.screenId })
        assertEquals(listOf("대화", "메시지 입력", "보내기"), first.screens[1].screenAnchors)
        assertNull("target 없는 요청", first.selector)

        val step = request("request_step.json")
        assertEquals("r2", step.requestId)
        assertEquals("알림 설정", step.selector)
    }

    @Test fun 형식이_틀린_요청은_null이고_NO_PATH_응답이_된다() {
        @Suppress("UNCHECKED_CAST") val ok = load("request_step.json") as Map<Any?, Any?>
        fun without(key: String) = ok.filterKeys { it != key }
        val bad = listOf(
            null, "문자열", emptyMap<String, Any>(),
            without("imagePath"),
            ok + ("imagePath" to " "),
            ok + ("imagePath" to 3),
            without("requestId"),
            without("guidance"),
            ok + ("guidance" to mapOf("packageName" to "")),
            ok + ("guidance" to mapOf("screens" to listOf(mapOf("screenId" to "a.b", "anchors" to listOf("홈", 1))))),
            ok + ("target" to mapOf("actionId" to "x.y")),
            ok + ("target" to "알림 설정"),
        )
        for (args in bad) assertNull(args.toString(), ChannelCodec.decode(args))

        val err = ChannelCodec.error(ChannelCodec.requestIdOf(without("imagePath")), ChannelCodec.NO_PATH)
        assertEquals("r2", err["requestId"])
        assertEquals("error", err["status"])
        assertEquals("NO_PATH", err["errorCode"])
        assertEquals("", ChannelCodec.requestIdOf(null))
    }

    @Test fun 오류_코드는_대문자_세_가지() =
        assertEquals(listOf("NO_PATH", "IMAGE_READ_FAILED", "ANALYSIS_FAILED"),
            listOf(ChannelCodec.NO_PATH, ChannelCodec.IMAGE_READ_FAILED, ChannelCodec.ANALYSIS_FAILED))

    // ---------- 응답 ----------

    @Test fun 응답의_키와_타입이_예시_파일과_같다() {
        for ((res, req) in cases) {
            val fixture = load(res)
            assertEquals(res, shape(fixture), shape(asJson(respond(request(req), fixture))))
        }
        val error = load("response_error.json")
        assertEquals(shape(error), shape(asJson(ChannelCodec.error("r5", ChannelCodec.IMAGE_READ_FAILED))))
    }

    // 키·타입뿐 아니라 값도 같다 = 같은 입력이면 Kotlin 규칙이 예시 파일(가짜 분석기와 공용)과 같은 screenId·target·pii 를 낸다
    @Test fun 응답_값이_예시_파일과_같다() {
        for ((res, req) in cases) {
            val fixture = load(res)
            assertEquals(res, fixture, asJson(respond(request(req), fixture)))
        }
        assertEquals(load("response_error.json"), asJson(ChannelCodec.error("r5", ChannelCodec.IMAGE_READ_FAILED)))
    }

    @Test fun 예시_응답이_뜻하는_것() {
        val step = request("request_step.json")
        val dup = respond(step, load("response_target_duplicate.json"))
        assertEquals("demo.settings", dup["screenId"])
        assertNull("같은 글자가 둘이면 고르지 않는다 (R3)", dup["target"])

        val fuzzy = respond(step, load("response_target_fuzzy.json"))
        assertEquals("fuzzy", (fuzzy["target"] as Map<*, *>)["match"])

        val ok = respond(step, load("response_ok.json"))
        assertEquals("exact", (ok["target"] as Map<*, *>)["match"])

        val first = request("request_first.json")
        assertNull("target 없는 요청이면 target null", respond(first, load("response_ok.json"))["target"])
    }

    @Test fun 개인정보는_가린_값과_9개_유형만_나간다() {
        val res = respond(request("request_first.json"), load("response_pii.json"))
        val pii = res["pii"] as List<*>
        assertEquals(1, pii.size)
        val json = gson.toJson(mapOf("pii" to pii, "piiEngine" to res["piiEngine"], "target" to res["target"]))
        assertFalse("pii 에 원문이 없다", json.contains("010-1234-5678"))
        assertFalse("pii 에 원문 일부(가운데)가 없다", json.contains("1234"))
        for (p in pii) assertTrue(PII_TYPES.contains((p as Map<*, *>)["type"]))
        // 응답 최상위에 원문 이미지·OCR 전문 칸이 없다
        assertEquals(setOf("requestId", "status", "errorCode", "imageSize", "screenId", "elements", "target",
            "pii", "piiEngine", "timingMs"), res.keys)
    }
}
