// P 화면 (협업규격 4.2 5번, 시스템설계 3-8, 검토 결론 5장). 흐름 규칙은 guide_flow_test "공유 전 확인 (P)"가 보고,
// 여기서는 DONE·기록의 "공유하기" 버튼과 P가 목록을 그리고 버튼을 보내는지만 본다. 장식 문구(제목)는 찾지 않는다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/app/app.dart';
import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/capture/data/sample_images.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/history/data/in_memory_history_repository.dart';
import 'package:screen_guide/features/history/domain/history.dart';
import 'package:screen_guide/features/privacy/ui/privacy_check_screen.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';

import '../../support/test_flow.dart';

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

/// chat 샘플로 안내를 끝까지 → DONE (후보 5건).
/// 위젯 시험의 가짜 시계 안에서는 분석기의 Future가 끝나지 않으므로 tester.runAsync로 부른다.
Future<GuideFlow> _toDone() async {
  final f = testFlow();
  await f.dispatch(ActionId.captureGallery);
  await f.dispatch(ActionId.capturePick, SampleImage.chat.id);
  await f.dispatch(ActionId.captureConfirm);
  await f.dispatch(ActionId.analyzeRun);
  await f.dispatch(ActionId.guideStart, f.availableActions.single);
  await f.dispatch(ActionId.guideNext);
  await f.dispatch(ActionId.guideNext);
  return f;
}

void main() {
  testWidgets('DONE "공유하기" → P: 후보가 줄마다 유형 + 가린 값, 저장 버튼은 없다', (tester) async {
    _phoneSize(tester);
    final f = (await tester.runAsync(_toDone))!;
    await tester.pumpWidget(ScreenGuideApp(flow: f));
    await tester.tap(find.text('공유하기'));
    await tester.pumpAndSettle();

    expect(f.screen, ScreenId.p);
    final c = f.shareDraft!.candidates;
    expect(find.text('개인정보 후보 ${c.length}건'), findsOneWidget);
    for (final x in c) {
      expect(
        find.text('·  ${x.type}   ${x.masked}'),
        findsWidgets,
        reason: '${x.type} 줄',
      );
    }
    expect(find.text('안내 기록에 저장'), findsNothing, reason: '3-8: P에는 확인·뒤로만');
    expect(find.textContaining('보증하지 않아요'), findsOneWidget, reason: '제약 C06');
  });

  testWidgets('"확인했어요" → SHARE로 (SHARE 화면은 5-5)', (tester) async {
    _phoneSize(tester);
    final f = (await tester.runAsync(_toDone))!;
    await tester.runAsync(() => f.dispatch(ActionId.sharePrepare));
    await tester.pumpWidget(ScreenGuideApp(flow: f));
    await tester.tap(find.text('확인했어요 · 사용 방법만 공유'));
    await tester.pumpAndSettle();
    expect(f.screen, ScreenId.share);
    expect(f.shareConfirmed, isTrue);
  });

  testWidgets('기록 펼침 "이 안내 공유하기" → P: 유형만 (가린 값 없음)', (tester) async {
    _phoneSize(tester);
    final history = InMemoryHistoryRepository();
    await history.save(
      HistoryEntry(
        id: 'a',
        actionId: 'chat.send',
        actionTitle: '메시지 보내기',
        stepInstructions: const ['보내기를 누르세요'],
        input: InputKind.gallery,
        createdAt: DateTime(2026, 11, 20),
        piiTypes: const ['휴대전화', '휴대전화'],
      ),
    );
    final f = testFlow(history: history);
    await tester.pumpWidget(ScreenGuideApp(flow: f));
    await tester.tap(find.byKey(const ValueKey('tab-history')));
    await tester.pumpAndSettle();
    expect(find.text('이 안내 공유하기'), findsNothing, reason: '접힌 카드에는 없다');

    await tester.tap(find.text('메시지 보내기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 안내 공유하기'));
    await tester.pumpAndSettle();

    expect(f.screen, ScreenId.p);
    expect(find.text('개인정보 후보 2건'), findsOneWidget);
    expect(find.text('·  휴대전화'), findsNWidgets(2), reason: '같은 유형도 줄마다');
  });

  testWidgets('후보 0건: 0건 문구와 보증하지 않음 안내', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyCheckScreen(
          candidates: const [],
          onConfirm: () {},
          onBack: () {},
        ),
      ),
    );
    expect(find.textContaining('개인정보 후보는 찾지 못했어요'), findsOneWidget);
    expect(find.text('개인정보 후보 0건'), findsOneWidget);
    expect(find.textContaining('보증하지 않아요'), findsOneWidget);
  });

  testWidgets('확인 버튼 동작이 없으면(관문이 막음) 눌리지 않는다', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyCheckScreen(
          candidates: const [ShareCandidate(type: '이메일')],
          onConfirm: null,
          onBack: () {},
        ),
      ),
    );
    final b = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(b.onPressed, isNull);
  });
}
