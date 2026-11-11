package com.screenguide.screen_guide

import com.screenguide.screen_guide.logic.*
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

// 분석 규칙 R1~R5 (제작범위 1-4, 협업규격_최종 3.3).
// a_/b_/c_ 는 Dart test/features/analyze/data/analyzers_test.dart 의 A·B·C 와 같은 입력·같은 기대값이다.
class RulesTest {
    private fun el(label: String, y: Int = 0) = UiElement(label, Box(0, y, 100, y + 10))
    private fun els(vararg l: String) = l.mapIndexed { i, s -> el(s, i * 20) }
    private fun maps(vararg s: Pair<String, List<String>>) = s.map { GuidanceMap(it.first, it.second) }
    private fun kinds(text: String) = merge(regexCandidates(text), text)
        .joinToString("; ") { text.substring(it.start, it.end) + "=" + it.type }.ifEmpty { "없음" }

    // ---------- R1: 앵커는 서로 다른 요소에서 ----------

    @Test fun a_한_줄이_앵커_두_개로_세어지지_않는다() {
        val g = maps("a.home" to listOf("설정", "알림 설정"))
        assertNull(identifyScreen(listOf(el("알림 설정")), g))
        assertEquals("a.home", identifyScreen(listOf(el("설정"), el("알림 설정", 20)), g)?.screenId)
    }

    @Test fun r1_한_요소는_앵커_하나에만_쓴다() =
        assertEquals(1, matchedAnchors(els("알림 설정"), listOf("알림", "설정")))

    @Test fun r1_최대_짝짓기_먼저_잡은_요소를_다른_앵커에_양보() {
        // 앵커 '설정'이 먼저 '알림 설정' 줄을 잡아도, '알림'이 그 줄을 쓰도록 '설정'을 '설정' 줄로 옮긴다 → 2
        assertEquals(2, matchedAnchors(els("알림 설정", "설정"), listOf("설정", "알림")))
    }

    @Test fun r1_줄_안의_단어_하나와_같아도_인정() =
        assertEquals("demo.chat", identifyScreen(els("홍길동 대화", "보내기"),
            maps("demo.chat" to listOf("대화", "메시지 입력", "보내기")))?.screenId)

    @Test fun r1_같은_글자_줄이_둘이면_앵커_둘을_채울_수_있다() =
        assertEquals(2, matchedAnchors(els("알림 설정", "알림 설정"), listOf("알림", "설정")))

    // ---------- R2: 가장 많이 맞은 화면, 같으면 null ----------

    @Test fun b_가장_많이_맞은_화면_같은_수면_식별하지_않는다() {
        val e = els("홈", "검색", "주문")
        assertEquals("a.two", identifyScreen(e, maps("a.one" to listOf("홈", "검색"), "a.two" to listOf("홈", "검색", "주문")))?.screenId)
        assertNull(identifyScreen(e, maps("a.one" to listOf("홈", "검색"), "a.two" to listOf("검색", "주문"))))
    }

    @Test fun r2_맵_순서와_관계없다() {
        val e = els("홈", "검색", "주문")
        assertEquals("a.two", identifyScreen(e, maps("a.two" to listOf("홈", "검색", "주문"), "a.one" to listOf("홈", "검색")))?.screenId)
    }

    @Test fun r2_동률_뒤에_더_많은_화면이_오면_그_화면() {
        val e = els("홈", "검색", "주문", "장바구니")
        assertEquals("a.three", identifyScreen(e, maps(
            "a.one" to listOf("홈", "검색"), "a.two" to listOf("검색", "주문"),
            "a.three" to listOf("홈", "주문", "장바구니")))?.screenId)
    }

    @Test fun r2_앵커_1개만_맞은_화면은_후보가_아니다() =
        assertNull(identifyScreen(els("홈", "검색"), maps("a.one" to listOf("홈", "주문"), "a.two" to listOf("검색", "설정"))))

    // ---------- R3: 하나뿐일 때만 ----------

    @Test fun c_같은_글자가_둘_이상이면_대상을_고르지_않는다() {
        assertNull(findTarget(listOf(el("보내기"), el("보내기", 20)), "보내기"))
        assertEquals(MatchKind.EXACT, findTarget(listOf(el("보내기")), "보내기")?.match)
        assertEquals(MatchKind.FUZZY, findTarget(listOf(el("보냬기")), "보내기")?.match)
        assertNull("한 글자는 오인식 허용 안 함", findTarget(listOf(el("앱")), "압"))
    }

    @Test fun r3_정확_일치가_둘이면_한_글자_차이로_넘어가지_않는다() =
        assertNull(findTarget(els("보내기", "보내기", "보냬기"), "보내기"))

    @Test fun r3_정확_일치가_하나면_한_글자_차이_요소가_있어도_exact() {
        val t = findTarget(els("보냬기", "보내기"), "보내기")
        assertEquals(MatchKind.EXACT, t?.match); assertEquals(20, t?.element?.box?.top)
    }

    @Test fun r3_띄어쓰기는_무시하고_정확_일치() =
        assertEquals(MatchKind.EXACT, findTarget(els("알림설정"), "알림 설정")?.match)

    @Test fun r3_한_글자_차이가_둘이면_null() = assertNull(findTarget(els("보냬기", "보내지"), "보내기"))

    @Test fun r3_길이가_다르면_fuzzy_아님() = assertNull(findTarget(els("보내기기"), "보내기"))

    // ---------- R4: 앞뒤가 숫자가 아님 (유형별 맞는 예·틀린 예) ----------
    // 계좌 추정 정규식은 '숫자-숫자-숫자' 를 넓게 잡으므로, 다른 유형의 틀린 예가 계좌 추정으로 잡히는 것도 기대값에 적었다.

    @Test fun r4_주민번호_맞는_예() {
        assertEquals("900101-1234567=주민·외국인등록번호", kinds("900101-1234567"))
        assertEquals("900101-1234567=주민·외국인등록번호", kinds("ID900101-1234567"))        // 영문과 붙음 (\b 로는 못 잡던 경우)
        assertEquals("900101-6234567=주민·외국인등록번호", kinds("(900101-6234567)"))
    }

    @Test fun r4_주민번호_틀린_예() {
        assertEquals("없음", kinds("900101-9234567"))     // 뒷자리 첫 숫자 9
        assertEquals("없음", kinds("901301-1234567"))     // 13월
        assertEquals("없음", kinds("1900101-1234567"))    // 앞에 숫자가 더 붙음
        assertEquals("없음", kinds("900101-12345678"))    // 뒤에 숫자가 더 붙음
    }

    @Test fun r4_휴대전화_맞는_예() {
        assertEquals("010-9876-5432=휴대전화", kinds("전화010-9876-5432번"))
        assertEquals("016-123-4567=휴대전화", kinds("016-123-4567"))
        assertEquals("01098765432=휴대전화", kinds("Tel.01098765432"))
        assertEquals("010-1234-5678=휴대전화", kinds("abc010-1234-5678def"))   // 영문과 붙음
    }

    @Test fun r4_휴대전화_틀린_예() {
        assertEquals("없음", kinds("01012345"))           // 자리 수 부족
        assertEquals("없음", kinds("010123456789"))       // 자리 수 초과
        assertEquals("010-1234-56789=계좌번호 추정", kinds("010-1234-56789"))   // 휴대전화 아님
        assertEquals("1010-1234-5678=계좌번호 추정", kinds("1010-1234-5678"))   // 숫자열 안의 010 은 휴대전화 아님
    }

    @Test fun r4_유선전화_맞는_예() {
        assertEquals("031-123-4567=유선전화", kinds("031-123-4567"))
        assertEquals("0212345678=유선전화", kinds("대표번호0212345678"))
        assertEquals("02-123-4567=유선전화; 010-1234-5678=휴대전화", kinds("전화 02-123-4567, 휴대 010-1234-5678"))
    }

    @Test fun r4_유선전화_틀린_예() {
        assertEquals("없음", kinds("0212345"))            // 자리 수 부족
        assertEquals("036-123-4567=계좌번호 추정", kinds("036-123-4567"))      // 없는 지역번호
        assertEquals("070-1234-5678=계좌번호 추정", kinds("070-1234-5678"))    // 인터넷전화는 유선전화 형식 밖
    }

    @Test fun r4_계좌번호_맞는_예() {
        assertEquals("1002-345-678901=계좌번호 추정", kinds("1002-345-678901"))
        assertEquals("333-12-345678-9=계좌번호 추정", kinds("333-12-345678-9"))
        assertEquals("3333-01-1234567=계좌번호 추정", kinds("계좌:3333-01-1234567"))
    }

    @Test fun r4_계좌번호_틀린_예() {
        assertEquals("없음", kinds("1999-12-31"))         // 날짜
        assertEquals("없음", kinds("12-34"))              // 두 덩어리
        assertEquals("없음", kinds("1-2-3"))              // 덩어리가 너무 짧음
        assertEquals("없음", kinds("가격 12,000원"))
    }

    // ---------- R5: 유형은 9개 중 하나 ----------

    @Test fun r5_유형은_9개() = assertEquals(9, PII_TYPES.size)

    @Test fun r5_겹치면_순서상_앞의_유형_하나() {
        val t = "서울시 010-1234-5678"
        val s = t.indexOf("010")
        val c = merge(regexCandidates(t) + Candidate(s, t.length, "전화") + Candidate(0, t.length, "주소"), t)
        assertEquals(1, c.size); assertEquals("휴대전화", c[0].type)
    }

    @Test fun r5_ML_Kit_유형끼리_겹치면_전화가_주소보다_앞() {
        val t = "서울시 중구 세종대로 110"
        val c = merge(listOf(Candidate(0, t.length, "주소"), Candidate(t.length - 3, t.length, "전화")), t)
        assertEquals("전화", c.single().type)
    }

    @Test fun r5_ML_Kit만_잡은_이메일() {
        val t = "메일 gildong@example.com"
        val c = merge(regexCandidates(t) + Candidate(3, t.length, "이메일"), t)
        assertEquals("이메일", c.single().type)
    }

    @Test fun r5_9개_밖의_유형은_버린다() {
        val t = "아무 글"
        assertEquals(0, merge(listOf(Candidate(0, 2, "기타"), Candidate(0, 2, "전화(ML Kit)")), t).size)
    }

    @Test fun r5_어떤_입력이든_9개_밖의_값이_나오지_않는다() {
        val texts = listOf("900101-1234567", "010-1234-5678", "02-123-4567", "110-123-456789", "abc", "")
        for (t in texts) for (c in merge(regexCandidates(t), t)) assertTrue(c.type, c.type in PII_TYPES)
    }

    // ---------- elementIndex ----------

    @Test fun pii_elementIndex는_후보가_든_요소() {
        val e = els("홍길동 대화", "네 맞아요. 연락은 010-1234-5678 로 주세요", "메시지 입력", "02-123-4567")
        val p = piiHits(e)
        assertEquals(listOf(1, 3), p.map { it.elementIndex })
        assertEquals(listOf("휴대전화", "유선전화"), p.map { it.type })
        assertEquals("010-****-**78", p[0].masked)
    }

    @Test fun pii_ML_Kit_후보가_줄을_넘으면_시작한_요소_안까지만_가린다() {
        val e = els("주소 서울시", "중구")
        val text = joinLabels(e)                            // "주소 서울시\n중구"
        val p = piiHits(e, listOf(Candidate(3, text.length, "주소")))
        assertEquals(0, p.single().elementIndex)
        assertEquals("서울시".length, p.single().masked.length)
    }

    @Test fun pii_요소가_없으면_빈_목록() = assertEquals(emptyList<PiiHit>(), piiHits(emptyList()))
}
