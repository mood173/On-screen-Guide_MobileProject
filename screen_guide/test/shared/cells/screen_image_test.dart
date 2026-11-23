// ScreenImage 위젯 시험: 좌표 변환 mapBox 연결과 크기 0 처리 (단위 D-3)
//
// 사진 파일은 없어도 된다 (없으면 깨진 그림 아이콘). 테두리 자리만 본다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/shared/cells/screen_image.dart';
import 'package:screen_guide/shared/contracts/analysis.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 400, child: child)),
  ),
);

void main() {
  const target = Box(100, 200, 300, 400);
  final targetBox = find.byKey(const ValueKey('target-box'));

  testWidgets('굵은 테두리가 mapBox 자리에 그려진다 (원본 700×1400 → 화면 175×350, ¼)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const ScreenImage(
          path: 'no_such_file.png',
          imageWidth: 700,
          imageHeight: 1400,
          target: target,
        ),
      ),
    );

    // 사진이 그려진 영역(AspectRatio)의 왼쪽 위를 0,0으로 놓고 비교한다
    final origin = tester.getTopLeft(find.byType(AspectRatio));
    final rect = tester.getRect(targetBox).shift(-origin);
    // mapBox 결과 (25, 50, 75, 100)에 테두리 여유 4를 더한 자리
    expect(rect, const Rect.fromLTRB(21, 46, 79, 104));
  });

  testWidgets('원본 크기가 0이면 깨지지 않고 사진만 그린다 (가로 0, 세로 0)', (tester) async {
    for (final (w, h) in [(0, 1400), (700, 0)]) {
      await tester.pumpWidget(
        _wrap(
          ScreenImage(
            path: 'no_such_file.png',
            imageWidth: w,
            imageHeight: h,
            target: target,
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: '크기 $w×$h');
      expect(targetBox, findsNothing, reason: '크기 $w×$h');
      expect(find.byType(Image), findsOneWidget, reason: '크기 $w×$h');
    }
  });
}
