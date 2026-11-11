package com.screenguide.screen_guide.logic

// 보고서 4.6·4.7의 로직. Android 의존성이 없어서 JVM 단위 시험(src/test)과 앱이 같은 코드를 쓴다.
// ML Kit의 Rect 대신 Box를 쓰고, Analyzer에서 변환한다.

data class Box(val left: Int, val top: Int, val right: Int, val bottom: Int)
data class OcrLine(val text: String, val box: Box?)
data class UiElement(val label: String, val box: Box)
data class GuidanceMap(val screenId: String, val screenAnchors: List<String>)
data class Candidate(val start: Int, val end: Int, val types: List<String>)

// 채널 응답에 실리는 결과 (계약 v1: target.match, pii[])
enum class MatchKind(val wire: String) { EXACT("exact"), FUZZY("fuzzy") }
data class TargetMatch(val element: UiElement, val match: MatchKind)
data class PiiHit(val type: String, val masked: String, val elementIndex: Int)

// ---------- F02 ----------
fun toUiElements(lines: List<OcrLine>): List<UiElement> =
    lines
        .filter { it.text.isNotBlank() && it.box != null }
        .map { UiElement(it.text.trim(), it.box!!) }
        .sortedWith(compareBy({ it.box.top }, { it.box.left }))

fun norm(s: String) = s.replace(Regex("""[\s·:]"""), "")

// OCR이 여러 단어를 한 줄로 묶어 읽는 경우("홍길동 대화")가 있어, 줄 전체 또는 줄 안의 단어 하나와 일치하면 인정
fun hasAnchor(label: String, anchor: String) =
    norm(label) == norm(anchor) || label.split(Regex("""\s+""")).any { norm(it) == norm(anchor) }

// R1: 앵커 몇 개가 "서로 다른 요소"에서 보이는가. 한 요소는 앵커 하나에만 쓴다.
// 앵커-요소 이분 그래프의 최대 짝짓기 수 (증가 경로, Kuhn). 입력이 작아(앵커 수 개 × 줄 수십 개) 단순 탐색으로 충분하다.
// fake_analyzer.dart 의 _matched 와 같은 알고리즘.
fun matchedAnchors(elements: List<UiElement>, anchors: List<String>): Int {
    val owner = HashMap<Int, Int>()   // 요소 번호 → 그 요소를 쓰고 있는 앵커 번호
    fun assign(a: Int, seen: MutableSet<Int>): Boolean {
        for (i in elements.indices) {
            if (i in seen || !hasAnchor(elements[i].label, anchors[a])) continue
            seen += i
            val prev = owner[i]
            if (prev == null || assign(prev, seen)) { owner[i] = a; return true }
        }
        return false
    }
    return anchors.indices.count { assign(it, HashSet()) }
}

// R2: 2개 이상 맞은 화면 중 맞은 수가 가장 많은 화면. 가장 많은 수가 같은 화면이 둘 이상이면 null (추정하지 않는다).
fun identifyScreen(elements: List<UiElement>, maps: List<GuidanceMap>): GuidanceMap? {
    var best: GuidanceMap? = null
    var bestN = 1
    var tie = false
    for (m in maps) {
        val n = matchedAnchors(elements, m.screenAnchors)
        if (n > bestN) { best = m; bestN = n; tie = false }
        else if (n == bestN && best != null) tie = true
    }
    return if (tie) null else best
}

// R3: 정확히 같은 요소가 하나일 때만 exact. 둘 이상이면 null.
// 정확 일치가 없으면 길이가 같고 한 글자만 다른 요소가 하나일 때만 fuzzy (선택자 2자 이상). 그 밖은 null.
fun findTarget(elements: List<UiElement>, selector: String): TargetMatch? {
    val s = norm(selector)
    val exact = elements.filter { norm(it.label) == s }
    if (exact.size == 1) return TargetMatch(exact[0], MatchKind.EXACT)
    if (exact.size > 1) return null
    if (s.length < 2) return null
    val near = elements.filter { val l = norm(it.label)
        l.length == s.length && l.zip(s).count { (a, b) -> a != b } == 1 }
    return near.singleOrNull()?.let { TargetMatch(it, MatchKind.FUZZY) }
}

// ---------- F03 ----------
val KR_PATTERNS = mapOf(
    "주민·외국인등록번호" to Regex("""\b\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])-?[1-8]\d{6}\b"""),
    "휴대전화"            to Regex("""\b01[016789]-?\d{3,4}-?\d{4}\b"""),
    "유선전화"            to Regex("""\b0(2|[3-6][1-5])-?\d{3,4}-?\d{4}\b"""),
    "계좌번호 추정"       to Regex("""\b\d{2,6}-\d{2,6}-\d{2,8}(-\d{1,6})?\b"""),
)
val DATE = Regex("""(19|20)\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])""")

fun regexCandidates(text: String) = KR_PATTERNS.flatMap { (kind, re) ->
    re.findAll(text).map { Candidate(it.range.first, it.range.last + 1, listOf(kind)) } }

// 1) 위치가 겹치는 후보를 하나로 합친다(ML Kit이 주민번호 뒷자리를 전화로 따로 잡는 경우 등)
// 2) 한국 형식 정규식 유형이 있으면 그것을 우선하고, ML Kit 유형은 정규식이 못 잡은 경우에만 쓴다
// 3) 전화번호 형식이면 계좌 후보에서 빼고, 날짜 형식은 어느 쪽이 잡았든 제외한다
fun merge(all: List<Candidate>, text: String): List<Candidate> {
    val groups = mutableListOf<Candidate>()
    for (c in all.sortedBy { it.start }) {
        val last = groups.lastOrNull()
        if (last != null && c.start < last.end)
            groups[groups.size - 1] = Candidate(last.start, maxOf(last.end, c.end), (last.types + c.types).distinct())
        else groups += c
    }
    return groups
        .map { c -> val kr = c.types.filter { it in KR_PATTERNS.keys }; if (kr.isNotEmpty()) c.copy(types = kr) else c }
        .map { c -> if (c.types.any { it.endsWith("전화") }) c.copy(types = c.types - "계좌번호 추정") else c }
        .filterNot { c -> DATE.matches(text.substring(c.start, c.end)) }
}

// 앞 3자·뒤 2자만 남기고 글자·숫자를 가린다(이메일 포함). 구분 기호(-, @, .)는 형식을 알아보도록 남긴다
fun mask(s: String): String =
    if (s.length <= 4) "*".repeat(s.length)
    else s.take(3) + s.drop(3).dropLast(2).map { if (it.isLetterOrDigit()) '*' else it }.joinToString("") + s.takeLast(2)
