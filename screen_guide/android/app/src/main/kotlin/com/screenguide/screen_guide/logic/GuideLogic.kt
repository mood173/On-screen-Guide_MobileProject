package com.screenguide.screen_guide.logic

// 보고서 4.6·4.7의 로직. Android 의존성이 없어서 JVM 단위 시험(src/test)과 앱이 같은 코드를 쓴다.
// ML Kit의 Rect 대신 Box를 쓰고, Analyzer에서 변환한다.

data class Box(val left: Int, val top: Int, val right: Int, val bottom: Int)
data class OcrLine(val text: String, val box: Box?)
data class UiElement(val label: String, val box: Box)
data class GuidanceMap(val screenId: String, val screenAnchors: List<String>)
data class Candidate(val start: Int, val end: Int, val type: String)   // type: PII_TYPES 중 하나

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
// R5: 개인정보 유형은 이 9개 중 하나 (협업규격_최종 3.3, analysis.dart piiTypes). 엔진 이름을 붙이지 않는다.
// 목록 순서가 우선순위다: 한국 형식 정규식 4개가 ML Kit 유형 5개보다 앞이고, 전화 형식이 계좌 추정보다 앞이다.
val PII_TYPES = listOf("주민·외국인등록번호", "휴대전화", "유선전화", "계좌번호 추정", "전화", "이메일", "주소", "카드", "URL")

// R4: \b 대신 "앞뒤가 숫자가 아님"((?<!\d) … (?!\d)). \b 는 한글·영문과 숫자 사이를 경계로 보는지가
// JVM 버전·Android 엔진마다 달라서(N2) JUnit 통과가 기기 동작을 보장하지 못했다.
// 이제 숫자열 안쪽에서 시작하거나 끝나는 것만 막고, 한글·영문·기호와 붙은 번호는 잡는다.
private const val ND_BEFORE = """(?<!\d)"""
private const val ND_AFTER = """(?!\d)"""
val KR_PATTERNS = mapOf(
    "주민·외국인등록번호" to Regex(ND_BEFORE + """\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])-?[1-8]\d{6}""" + ND_AFTER),
    "휴대전화"            to Regex(ND_BEFORE + """01[016789]-?\d{3,4}-?\d{4}""" + ND_AFTER),
    "유선전화"            to Regex(ND_BEFORE + """0(2|[3-6][1-5])-?\d{3,4}-?\d{4}""" + ND_AFTER),
    "계좌번호 추정"       to Regex(ND_BEFORE + """\d{2,6}-\d{2,6}-\d{2,8}(-\d{1,6})?""" + ND_AFTER),
)
val DATE = Regex("""(19|20)\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])""")

fun regexCandidates(text: String) = KR_PATTERNS.flatMap { (kind, re) ->
    re.findAll(text).map { Candidate(it.range.first, it.range.last + 1, kind) } }

// 1) 위치가 겹치는 후보를 하나로 합친다(ML Kit이 주민번호 뒷자리를 전화로 따로 잡는 경우 등)
// 2) 합친 후보의 유형은 PII_TYPES 순서로 가장 앞의 것 하나 (R5). 그래서
//    - 한국 형식 정규식 유형이 있으면 그것, ML Kit 유형은 정규식이 못 잡은 경우에만 쓴다
//    - 전화 형식(휴대·유선)과 계좌 추정이 겹치면 전화
//    - 9개 밖의 유형만 있는 후보는 버린다
// 3) 날짜 형식은 어느 쪽이 잡았든 제외한다
fun merge(all: List<Candidate>, text: String): List<Candidate> {
    data class Group(val start: Int, var end: Int, val types: MutableSet<String>)
    val groups = mutableListOf<Group>()
    for (c in all.sortedBy { it.start }) {
        val last = groups.lastOrNull()
        if (last != null && c.start < last.end) { last.end = maxOf(last.end, c.end); last.types += c.type }
        else groups += Group(c.start, c.end, mutableSetOf(c.type))
    }
    return groups.mapNotNull { g ->
        val type = g.types.filter { it in PII_TYPES }.minByOrNull { PII_TYPES.indexOf(it) } ?: return@mapNotNull null
        Candidate(g.start, g.end, type)
    }.filterNot { c -> DATE.matches(text.substring(c.start, c.end)) }
}

// 요소 글자를 "\n"으로 이어 붙인 글. 정규식과 ML Kit 개체 추출이 이 글 하나를 본다.
fun joinLabels(elements: List<UiElement>) = elements.joinToString("\n") { it.label }

// 후보마다 몇 번째 요소에 들어 있는지(elementIndex)와 가린 값을 계산한다.
// extra: ML Kit 후보 (joinLabels 글 기준 위치). 후보가 줄을 넘어가면 시작한 요소 안까지만 가린다.
fun piiHits(elements: List<UiElement>, extra: List<Candidate> = emptyList()): List<PiiHit> {
    if (elements.isEmpty()) return emptyList()
    val text = joinLabels(elements)
    val starts = elements.runningFold(0) { acc, e -> acc + e.label.length + 1 }.dropLast(1)   // 요소별 시작 위치
    return merge(regexCandidates(text) + extra, text).map { c ->
        val idx = starts.indexOfLast { it <= c.start }
        val end = minOf(c.end, starts[idx] + elements[idx].label.length)
        PiiHit(c.type, mask(text.substring(c.start, end)), idx)
    }
}

// 앞 3자·뒤 2자만 남기고 글자·숫자를 가린다(이메일 포함). 구분 기호(-, @, .)는 형식을 알아보도록 남긴다
fun mask(s: String): String =
    if (s.length <= 4) "*".repeat(s.length)
    else s.take(3) + s.drop(3).dropLast(2).map { if (it.isLetterOrDigit()) '*' else it }.joinToString("") + s.takeLast(2)
