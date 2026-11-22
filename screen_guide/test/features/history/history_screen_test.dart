// HISTORY 화면 (협업규격 4.2 5번, 시스템설계 3-9). 흐름 규칙은 guide_flow_test "기록 화면"이 보고, 여기서는 화면이 값을 그리고 버튼을 보내는지만 본다.
// 장식 문구(제목·부제)는 Figma가 바뀌면 같이 바뀌므로 찾지 않는다. 문서가 뜻을 정한 글자(지우기, 확인창, 0건 안내)만 본다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/app/app.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/history/data/in_memory_history_repository.dart';
import 'package:screen_guide/features/history/domain/history.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';

import '../../support/test_flow.dart';

HistoryEntry _entry(String id, String title, InputKind input) => HistoryEntry(
  id: id,
  actionId: 'chat.send',
  actionTitle: title,
  stepInstructions: const ['입력창을 누르세요', '보내기를 누르세요'],
  input: input,
  createdAt: DateTime(2026, 11, 20, 10, 5),
);

/// 홈에서 기록 탭을 눌러 HISTORY까지 간다.
Future<InMemoryHistoryRepository> _openHistory(
  WidgetTester tester, {
  List<HistoryEntry> saved = const [],
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  final history = InMemoryHistoryRepository();
  for (final e in saved) {
    await history.save(e);
  }
  final flow = testFlow(history: history);
  await tester.pumpWidget(ScreenGuideApp(flow: flow));
  await tester.tap(find.byKey(const ValueKey('tab-history')));
  await tester.pumpAndSettle();
  expect(flow.screen, ScreenId.history);
  return history;
}

void main() {
  testWidgets('기록 0건: 안내 문구가 보인다', (tester) async {
    await _openHistory(tester);
    expect(find.textContaining('아직 저장한 안내가 없어요'), findsOneWidget);
    expect(find.text('지우기'), findsNothing);
  });

  testWidgets('기록이 있으면: 기능 제목, 입력 방식 · 시각, 개수가 보인다', (tester) async {
    await _openHistory(
      tester,
      saved: [_entry('a', '메시지 보내기', InputKind.camera)],
    );
    expect(find.text('메시지 보내기'), findsOneWidget);
    expect(find.text('카메라 촬영  ·  11월 20일 10:05'), findsOneWidget);
    expect(find.textContaining('1개'), findsOneWidget);
    expect(find.textContaining('아직 저장한 안내가 없어요'), findsNothing);
  });

  testWidgets('카드를 누르면 단계 문구가 펼쳐지고, 뒤로 키를 누르면 접힌다', (tester) async {
    await _openHistory(
      tester,
      saved: [_entry('a', '메시지 보내기', InputKind.gallery)],
    );
    expect(find.text('1. 입력창을 누르세요'), findsNothing);

    await tester.tap(find.text('메시지 보내기'));
    await tester.pumpAndSettle();
    expect(find.text('1. 입력창을 누르세요'), findsOneWidget);
    expect(find.text('2. 보내기를 누르세요'), findsOneWidget);

    await tester.binding.handlePopRoute(); // 기기 뒤로 키
    await tester.pumpAndSettle();
    expect(find.text('1. 입력창을 누르세요'), findsNothing);
    expect(find.text('메시지 보내기'), findsOneWidget, reason: '목록에 그대로');
  });

  testWidgets('지우기: [취소]면 그대로, [지우기]면 저장소와 목록에서 사라진다', (tester) async {
    final history = await _openHistory(
      tester,
      saved: [_entry('a', '메시지 보내기', InputKind.gallery)],
    );

    await tester.tap(find.byKey(const ValueKey('delete-a')));
    await tester.pumpAndSettle();
    expect(find.text('이 기록을 지울까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('메시지 보내기'), findsOneWidget);
    expect(await history.get('a'), isNotNull);

    await tester.tap(find.byKey(const ValueKey('delete-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '지우기').last); // 확인창 안의 버튼
    await tester.pumpAndSettle();
    expect(find.text('메시지 보내기'), findsNothing);
    expect(await history.get('a'), isNull);
    expect(find.textContaining('아직 저장한 안내가 없어요'), findsOneWidget);
  });

  testWidgets('하단 탭: 기록 탭이 켜져 있고, 홈 탭을 누르면 홈으로', (tester) async {
    await _openHistory(tester);
    // 지금 탭은 다시 눌러도 할 일이 없어 막혀 있다
    final historyTab = tester.widget<InkWell>(
      find.byKey(const ValueKey('tab-history')),
    );
    expect(historyTab.onTap, isNull);

    await tester.tap(find.byKey(const ValueKey('tab-home')));
    await tester.pumpAndSettle();
    expect(find.text('어떤 방법으로 시작할까요?'), findsOneWidget);
  });
}
