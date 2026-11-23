// SHARE 화면 (협업규격 4.2 5번, 시스템설계 3-8 "보낼 텍스트 미리보기"). 보내기 흐름 규칙은 guide_flow_test "보내기 (SHARE)"가 보고,
// 여기서는 화면이 보낼 글을 그대로 보여 주고 버튼을 보내는지만 본다. 장식 문구(제목)는 찾지 않는다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/app/app.dart';
import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/capture/data/sample_images.dart';
import 'package:screen_guide/features/share/data/fake_sharer.dart';
import 'package:screen_guide/features/share/ui/share_screen.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';

import '../../support/test_flow.dart';

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

/// chat 샘플로 안내 끝 → 공유하기 → 확인했어요 → SHARE.
/// 위젯 시험의 가짜 시계 안에서는 분석기의 Future가 끝나지 않으므로 tester.runAsync로 부른다.
Future<GuideFlow> _toShare(FakeSharer sharer) async {
  final f = testFlow(sharer: sharer);
  await f.dispatch(ActionId.captureGallery);
  await f.dispatch(ActionId.capturePick, SampleImage.chat.id);
  await f.dispatch(ActionId.captureConfirm);
  await f.dispatch(ActionId.analyzeRun);
  await f.dispatch(ActionId.guideStart, f.availableActions.single);
  await f.dispatch(ActionId.guideNext);
  await f.dispatch(ActionId.guideNext);
  await f.dispatch(ActionId.sharePrepare);
  await f.dispatch(ActionId.shareConfirm);
  return f;
}

void main() {
  testWidgets('미리보기 = 보낼 글: 글자를 바꾸지 않고 그대로 보인다, "체험" 문구 없음', (tester) async {
    _phoneSize(tester);
    final f = (await tester.runAsync(() => _toShare(FakeSharer())))!;
    await tester.pumpWidget(ScreenGuideApp(flow: f));
    expect(f.screen, ScreenId.share);

    final text = f.shareText!;
    final cut = text.indexOf('\n');
    expect(find.text(text.substring(0, cut)), findsOneWidget, reason: '첫 줄');
    expect(find.text(text.substring(cut + 1)), findsOneWidget, reason: '나머지');
    expect(find.textContaining('체험'), findsNothing);
  });

  testWidgets('"보내기" → 보이는 글 그대로 보내고 마무리로, "공유했어요"', (tester) async {
    _phoneSize(tester);
    final sharer = FakeSharer();
    final f = (await tester.runAsync(() => _toShare(sharer)))!;
    await tester.pumpWidget(ScreenGuideApp(flow: f));
    final shown = f.shareText!;

    await tester.tap(find.text('보내기'));
    await tester.pumpAndSettle();
    expect(sharer.sent, [shown]);
    expect(f.screen, ScreenId.done);
    expect(find.text('공유했어요'), findsOneWidget, reason: '안내 문구(스낵바)');
  });

  testWidgets('"돌아가기" → P (확인함은 그대로)', (tester) async {
    _phoneSize(tester);
    final f = (await tester.runAsync(() => _toShare(FakeSharer())))!;
    await tester.pumpWidget(ScreenGuideApp(flow: f));
    await tester.tap(find.text('돌아가기'));
    await tester.pumpAndSettle();
    expect(f.screen, ScreenId.p);
    expect(f.shareConfirmed, isTrue);
  });

  testWidgets('보내기 동작이 없으면(관문이 막음) 눌리지 않는다', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: ShareScreen(
          text: '제목 · 사용 방법\n1. 하나',
          onSend: null,
          onBack: null,
        ),
      ),
    );
    final b = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(b.onPressed, isNull);
  });
}
