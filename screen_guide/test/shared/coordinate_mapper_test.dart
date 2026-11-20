// 좌표 변환 mapBox 단위 시험 (협업규격_최종 4.2 4번, 역할설계 98줄 "원본 상자 ↔ 화면 사각형 단위 시험")
//
// 비율은 ½·¼처럼 정확히 표현되는 값만 골라서 결과를 그대로(==) 비교한다.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/shared/contracts/analysis.dart';
import 'package:screen_guide/shared/coordinate_mapper.dart';

void main() {
  group('mapBox', () {
    const box = Box(100, 200, 300, 400);

    test('같은 크기면 그대로', () {
      final r = mapBox(
        box,
        image: const Size(1080, 2400),
        view: const Size(1080, 2400),
      );
      expect(r, const Rect.fromLTRB(100, 200, 300, 400));
    });

    test('반으로 그리면 반', () {
      final r = mapBox(
        box,
        image: const Size(1080, 2400),
        view: const Size(540, 1200),
      );
      expect(r, const Rect.fromLTRB(50, 100, 150, 200));
    });

    test('가로·세로 비율이 달라도 따로 계산한다 (가로 ¼, 세로 ½)', () {
      final r = mapBox(
        box,
        image: const Size(1000, 2000),
        view: const Size(250, 1000),
      );
      expect(r, const Rect.fromLTRB(25, 100, 75, 200));
    });

    test('사진 전체 상자는 화면 전체', () {
      final r = mapBox(
        const Box(0, 0, 1080, 2400),
        image: const Size(1080, 2400),
        view: const Size(270, 600),
      );
      expect(r, const Rect.fromLTRB(0, 0, 270, 600));
    });

    test('계약 예시 파일의 실제 값 (response_ok.json "알림 설정", ¼ 크기)', () {
      final r = mapBox(
        const Box(174, 1029, 341, 1070),
        image: const Size(1080, 2340),
        view: const Size(270, 585),
      );
      expect(r, const Rect.fromLTRB(43.5, 257.25, 85.25, 267.5));
    });

    test('원본 크기가 0이면 빈 사각형 (0으로 나누지 않는다)', () {
      expect(
        mapBox(box, image: const Size(0, 2400), view: const Size(270, 600)),
        Rect.zero,
      );
      expect(
        mapBox(box, image: const Size(1080, 0), view: const Size(270, 600)),
        Rect.zero,
      );
    });

    test('화면 크기가 0이면 크기 0인 사각형', () {
      final r = mapBox(box, image: const Size(1080, 2400), view: Size.zero);
      expect(r, Rect.zero);
    });
  });
}
