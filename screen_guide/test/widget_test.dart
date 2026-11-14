import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/app/app.dart';
import 'package:screen_guide/features/analyze/data/fake_analyzer.dart';

import 'support/test_flow.dart';

void main() {
  testWidgets('홈에서 갤러리 → 샘플 선택 → 분석 → 기능 선택 → 단계 안내 → 완료까지 화면이 넘어간다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final flow = testFlow(
      analyzer: FakeAnalyzer(delay: const Duration(milliseconds: 300)),
    );
    await tester.pumpWidget(ScreenGuideApp(flow: flow));

    expect(find.text('어떤 방법으로 시작할까요?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('input-gallery')));
    await tester.pumpAndSettle();

    expect(find.text('최근 이미지'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('thumb-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 이미지 사용'));
    await tester.pumpAndSettle();

    expect(find.text('이 이미지로 안내받을까요?'), findsOneWidget);
    await tester.tap(find.text('이 화면 분석하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('이미지 분석 중'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('무엇을 하고 싶으세요?'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('action-settings.notification')),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('단계별 안내 · 1 / 1'), findsOneWidget);
    expect(find.text('알림 설정을 눌러주세요'), findsOneWidget);
    expect(find.byKey(const ValueKey('target-box')), findsOneWidget);

    await tester.tap(find.text('안내 완료'));
    await tester.pumpAndSettle();
    expect(find.text('잘 따라오셨어요!'), findsOneWidget);
  });

  // 카메라 세션에서 CR·CA·RC가 갤러리 화면 위젯을 재사용해 그려지는지 (시스템설계 3-0)
  testWidgets('홈에서 카메라 → 촬영 → 촬영한 사진 → 사진 분석 중 → 분석 결과까지 화면이 넘어간다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final flow = testFlow(
      analyzer: FakeAnalyzer(delay: const Duration(milliseconds: 300)),
    );
    await tester.pumpWidget(ScreenGuideApp(flow: flow));

    await tester.tap(find.byKey(const ValueKey('input-camera'))); // H → CP
    await tester.pumpAndSettle();
    // CP 화면은 4.2 4번 단위 C에서 만든다. 그때까지 홈 화면이 대신 보이고, 카메라 타일이 촬영 버튼 역할을 한다.
    // CP → 촬영 → CR
    await tester.tap(find.byKey(const ValueKey('input-camera')));
    await tester.pumpAndSettle();

    expect(find.text('촬영한 사진'), findsOneWidget);
    expect(find.text('카메라로 촬영  ·  이미지 1개'), findsOneWidget);
    await tester.tap(find.text('이 화면 분석하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('사진 분석 중'), findsOneWidget);
    expect(find.text('카메라 촬영 · 기기 내부에서 처리 중'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('무엇을 하고 싶으세요?'), findsOneWidget);
  });
}
