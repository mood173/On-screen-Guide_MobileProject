import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/app/app.dart';
import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/analyze/data/fake_analyzer.dart';

void main() {
  testWidgets('홈에서 갤러리 → 샘플 선택 → 분석 → 기능 선택 → 단계 안내 → 완료까지 화면이 넘어간다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final flow = GuideFlow(
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
}
