package com.screenguide.screen_guide

import com.screenguide.screen_guide.logic.*
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

// 보고서 부록 A 단위 시험(23건)을 JUnit으로 옮긴 것. 앱과 같은 GuideLogic.kt를 시험한다.
class GuideLogicTest {
    private fun kinds(text: String) = merge(regexCandidates(text), text)
        .joinToString("; ") { text.substring(it.start, it.end) + "=" + it.types.joinToString("+") }.ifEmpty { "없음" }
    private val r = Box(0, 0, 10, 10)
    private fun els(vararg l: String) = l.map { UiElement(it, r) }

    @Test fun r01_주민번호() = assertEquals("900101-1234567=주민·외국인등록번호", kinds("주민번호 900101-1234567"))
    @Test fun r02_주민번호_붙여쓰기() = assertEquals("9001011234567=주민·외국인등록번호", kinds("9001011234567"))
    @Test fun r03_한글_붙음() = assertEquals("900101-2234567=주민·외국인등록번호", kinds("번호는900101-2234567입니다"))
    @Test fun r04_외국인등록번호() = assertEquals("900101-5234567=주민·외국인등록번호", kinds("외국인등록번호 900101-5234567"))
    @Test fun r05_같은형식_다른번호는_후보표시() = assertEquals("2510231234567=주민·외국인등록번호", kinds("주문번호 2510231234567"))
    @Test fun r06_휴대전화() = assertEquals("010-1234-5678=휴대전화", kinds("010-1234-5678"))
    @Test fun r07_휴대전화_붙여쓰기() = assertEquals("01012345678=휴대전화", kinds("01012345678"))
    @Test fun r08_휴대전화_011() = assertEquals("011-123-4567=휴대전화", kinds("011-123-4567"))
    @Test fun r09_계좌번호() = assertEquals("110-123-456789=계좌번호 추정", kinds("110-123-456789"))
    @Test fun r10_날짜는_제외() = assertEquals("없음", kinds("2026-10-23"))
    @Test fun r11_유선전화() = assertEquals("02-123-4567=유선전화", kinds("02-123-4567"))
    @Test fun r12_개인정보_없음() = assertEquals("없음", kinds("설정 알림 검색 홈"))

    @Test fun m01_중복후보_병합() {
        val t = "연락처 010-1234-5678"; val m = merge(regexCandidates(t), t)
        assertEquals(1, m.size); assertEquals(listOf("휴대전화"), m[0].types)
    }
    @Test fun n01_정규화() = assertEquals("알림설정", norm("알림 설정"))
    @Test fun t01_정확일치() = assertEquals("설정", findTarget(els("설정", "알림"), "설정")?.label)
    @Test fun t02_OCR_오인식_한글자() = assertEquals("설장", findTarget(els("설장", "알림"), "설정")?.label)
    @Test fun t03_후보_2개_이상() = assertNull(findTarget(els("검샥", "감색"), "검색"))
    @Test fun t04_없음() = assertNull(findTarget(els("알림", "홈"), "결제"))
    @Test fun t05_짧은라벨_오매칭_방지() = assertNull(findTarget(els("검", "홈"), "검색"))
    @Test fun t06_한글자_선택자_오매칭_방지() = assertNull(findTarget(els("옴", "메뉴"), "홈"))

    private val maps = listOf(GuidanceMap("home", listOf("홈", "내 정보")), GuidanceMap("settings", listOf("설정", "알림 설정")))
    @Test fun s01_화면식별() = assertEquals("home", identifyScreen(els("홈", "내정보", "검색"), maps)?.screenId)
    @Test fun s02_앵커_1개만() = assertNull(identifyScreen(els("설정", "검색"), maps))

    @Test fun u01_정렬과_빈줄제외() {
        val s = toUiElements(listOf(OcrLine("아래", Box(0, 200, 50, 220)), OcrLine("오른쪽", Box(100, 10, 150, 30)),
            OcrLine("왼쪽", Box(0, 10, 50, 30)), OcrLine("  ", Box(0, 0, 1, 1)), OcrLine("상자없음", null)))
        assertEquals("왼쪽,오른쪽,아래", s.joinToString(",") { it.label })
    }

    // ---- 에뮬레이터 1차 시험에서 발견해 추가한 시험 (실제 ML Kit 출력 재현) ----
    @Test fun e01_한줄로_묶인_앵커도_화면식별() =
        assertEquals("chat", identifyScreen(els("홍길동 대화", "보내기"), SAMPLE_MAPS)?.screenId)
    @Test fun e02_ML_Kit가_날짜를_전화로_잡아도_제외() {
        val t = "2026-10-23"
        val c = merge(regexCandidates(t) + Candidate(0, 10, listOf("전화(ML Kit)")), t)
        assertEquals(0, c.size)
    }
    @Test fun e03_주민번호_뒷자리_전화오탐은_주민번호로_합침() {
        val t = "본인 확인용으로 900101-1234567 남겨"
        val s = t.indexOf("900101"); val back = t.indexOf("1234567")
        val c = merge(regexCandidates(t) + Candidate(back, back + 7, listOf("전화(ML Kit)")), t)
        assertEquals(1, c.size); assertEquals(listOf("주민·외국인등록번호"), c[0].types); assertEquals(s, c[0].start)
    }
    @Test fun e04_계좌를_ML_Kit가_전화로_잡으면_계좌_유지() {
        val t = "110-123-456789"
        val c = merge(regexCandidates(t) + Candidate(0, t.length, listOf("전화(ML Kit)")), t)
        assertEquals(listOf("계좌번호 추정"), c[0].types)
    }
    @Test fun e05_이메일_가림() = assertEquals("gil****@*******.*om", mask("gildong@example.com"))
}
