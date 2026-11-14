import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/app/app.dart';
import 'package:screen_guide/features/analyze/data/fake_analyzer.dart';
import 'package:screen_guide/features/capture/data/fake_input.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';

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
    // Figma CP(15:113) 문구 (버튼·카드 둘째 줄은 11/14 결정대로 바꿈)
    expect(find.text('카메라 접근'), findsOneWidget);
    expect(find.text('카메라로 화면을\n찍어볼까요?'), findsOneWidget);
    expect(find.text('카메라 접근이 필요해요'), findsOneWidget);
    expect(find.text('촬영할 때만 카메라를 사용해요.\n찍은 사진은 안내가 끝나면 지워요.'), findsOneWidget);
    expect(find.textContaining('체험'), findsNothing);
    await tester.tap(find.text('카메라 허용')); // CP → 촬영 → CR
    await tester.pumpAndSettle();

    // Figma CR(15:125) 문구
    expect(find.text('촬영한 사진'), findsOneWidget);
    expect(find.text('촬영한 화면을 확인하세요'), findsOneWidget);
    expect(find.text('카메라 촬영  ·  방금 전'), findsOneWidget);
    expect(find.text('다시 촬영'), findsOneWidget);
    await tester.tap(find.text('이 화면 분석하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('사진 분석 중'), findsOneWidget);
    expect(find.text('카메라 촬영 · 기기 내부에서 처리 중'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('무엇을 하고 싶으세요?'), findsOneWidget);
    expect(find.text('카메라 분석 결과'), findsOneWidget); // Figma RC 제목
  });

  // 권한 안내 화면: 거부된 입력 방식에 따라 문구·버튼 이름이 다르다 (기능별_검토_결론, 필수)
  testWidgets('카메라 거부 → DENY "카메라 권한이 허용되지 않았어요" → 갤러리에서 선택', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final flow = testFlow(
      camera: FakeCameraInput(status: PickStatus.permissionDenied),
    );
    await tester.pumpWidget(ScreenGuideApp(flow: flow));
    await tester.tap(find.byKey(const ValueKey('input-camera'))); // H → CP
    await tester.pumpAndSettle();
    await tester.tap(find.text('카메라 허용')); // 촬영 → 거부
    await tester.pumpAndSettle();

    expect(find.text('권한이 필요해요'), findsOneWidget);
    expect(find.text('카메라 권한이\n허용되지 않았어요'), findsOneWidget);
    expect(find.text('카메라 권한 확인'), findsOneWidget);
    expect(find.text('실시간 권한 확인'), findsNothing, reason: '13장 X5');
    await tester.tap(find.text('갤러리에서 선택'));
    await tester.pumpAndSettle();
    expect(find.text('최근 이미지'), findsOneWidget);
  });

  testWidgets('갤러리 거부 → DENY "사진 접근 권한이 허용되지 않았어요" → 다시 시도', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final gallery = FakeGalleryInput(
      access: PickStatus.permissionDenied,
      loadThumbnail: noThumbnail,
    );
    await tester.pumpWidget(ScreenGuideApp(flow: testFlow(gallery: gallery)));
    await tester.tap(find.byKey(const ValueKey('input-gallery')));
    await tester.pumpAndSettle();

    expect(find.text('사진 접근 권한이\n허용되지 않았어요'), findsOneWidget);
    expect(find.text('사진 권한 확인'), findsOneWidget);
    gallery.access = PickStatus.ok; // 설정에서 허용하고 돌아옴
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('최근 이미지'), findsOneWidget);
  });

  testWidgets('CP에서 "지금은 허용하지 않기" → 홈으로', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ScreenGuideApp(flow: testFlow()));
    await tester.tap(find.byKey(const ValueKey('input-camera'))); // H → CP
    await tester.pumpAndSettle();
    await tester.tap(find.text('지금은 허용하지 않기'));
    await tester.pumpAndSettle();
    expect(find.text('어떤 방법으로 시작할까요?'), findsOneWidget);
  });
}
