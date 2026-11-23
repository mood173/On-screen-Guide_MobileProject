package com.screenguide.screen_guide

import com.screenguide.screen_guide.logic.uprightSize
import org.junit.Assert.assertEquals
import org.junit.Test

// 응답 imageSize는 "세워진" 이미지 기준이다 (EXIF 회전 적용).
// ML Kit 상자 좌표가 회전 후 기준이므로 90/270도에서만 가로·세로를 맞바꾼다.
// 회귀 근거: Analyzer.kt 가 InputImage.width/height(회전 전)를 그대로 보내 상자가 어긋나던 결함.
class UprightSizeTest {
    @Test fun 정방향은_그대로_둔다() =
        assertEquals(1080 to 2400, uprightSize(1080, 2400, 0))

    @Test fun _180도는_크기가_같다() =
        assertEquals(1080 to 2400, uprightSize(1080, 2400, 180))

    @Test fun _90도는_가로세로를_바꾼다() =
        assertEquals(2400 to 1080, uprightSize(1080, 2400, 90))

    @Test fun _270도는_가로세로를_바꾼다() =
        assertEquals(2400 to 1080, uprightSize(1080, 2400, 270))

    @Test fun 음수와_360초과도_정규화한다() {
        assertEquals(2400 to 1080, uprightSize(1080, 2400, -90))
        assertEquals(2400 to 1080, uprightSize(1080, 2400, 450))
        assertEquals(1080 to 2400, uprightSize(1080, 2400, 360))
    }
}
