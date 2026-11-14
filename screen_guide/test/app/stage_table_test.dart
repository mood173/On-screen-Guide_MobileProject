import 'package:flutter_test/flutter_test.dart';
import 'package:screen_guide/app/stage.dart';
import 'package:screen_guide/app/stage_table.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';

import '../support/test_flow.dart';

void main() {
  test('모든 단계에 규칙이 있다', () {
    for (final stage in Stage.values) {
      expect(StageTable.rules.containsKey(stage), isTrue, reason: '$stage');
    }
  });

  test('장면별 목록은 그 단계의 화면이고, 단계 기본보다 넓지 않다', () {
    for (final MapEntry(key: stage, value: rule) in StageTable.rules.entries) {
      for (final MapEntry(key: screen, value: ids) in rule.byScene.entries) {
        expect(screen.stage, stage, reason: '${screen.code}는 $stage가 아님');
        expect(
          rule.allowed.containsAll(ids),
          isTrue,
          reason: '${screen.code}의 목록이 단계 기본을 넘음',
        );
      }
    }
  });

  test('공유 관문: shareSend는 SHARE 장면에서만 열린다 (P를 거쳐야 보냄)', () {
    final opened = [
      for (final s in ScreenId.values)
        if (StageTable.allowedOn(s).contains(ActionId.shareSend)) s,
    ];
    expect(opened, [ScreenId.share]);
  });

  // GuideFlow의 관문이 표를 그대로 쓰는지 (상태 잠금이 없을 때).
  test('GuideFlow 관문 = 표 결과 (모든 화면, shareSend 제외)', () {
    final flow = testFlow();
    for (final s in ScreenId.values) {
      flow.screen = s;
      final fromTable = {...StageTable.always, ...StageTable.allowedOn(s)}
        ..remove(ActionId.shareSend); // 확인 전이라 잠김 (아래 시험)
      expect(flow.allowed, fromTable, reason: s.code);
    }
  });

  test('홈(navHome)은 앱 셸 탭(H·HISTORY·SETTINGS)과 마무리(DONE)·오류(E)에서만 열린다 (3-7·3-9·4-1)', () {
    final flow = testFlow();
    final opened = {
      for (final s in ScreenId.values)
        if ((flow..screen = s).allows(ActionId.navHome)) s,
    };
    expect(opened, {
      ScreenId.h,
      ScreenId.history,
      ScreenId.settings,
      ScreenId.done,
      ScreenId.e,
    });
  });

  // 화면 틀 (시스템설계 4-1)
  test('셸과 진행 칸이 시스템설계 4-1·3장 표와 같다', () {
    const expected = <Stage, (Shell, int?)>{
      Stage.ready: (Shell.start, null),
      Stage.waiting: (Shell.app, null),
      Stage.input: (Shell.guide, 1),
      Stage.analyze: (Shell.guide, 2),
      Stage.choose: (Shell.guide, 3),
      Stage.guide: (Shell.guide, 4),
      Stage.finish: (Shell.guide, 5),
      Stage.share: (Shell.share, null),
      Stage.recover: (Shell.guide, null), // 실패한 단계 칸 — 흐름 시험에서 확인
      Stage.records: (Shell.app, null),
      Stage.overlay: (Shell.overlay, null),
    };
    for (final MapEntry(key: stage, value: (shell, progress))
        in expected.entries) {
      final rule = StageTable.rules[stage]!;
      expect(rule.shell, shell, reason: '$stage 셸');
      expect(rule.progress, progress, reason: '$stage 진행 칸');
    }
  });

  test('앱 셸 화면에서는 하단 탭 3개가 열리고, 다른 셸에서는 안 열린다', () {
    for (final s in ScreenId.values) {
      final isApp = StageTable.ruleOf(s).shell == Shell.app;
      final opened = StageTable.allowedOn(s)
          .containsAll(StageTable.appShellTabs);
      expect(opened, isApp, reason: s.code);
    }
  });

  // "확인 후에는 열린다"는 확인 버튼(shareConfirm)을 만들 때(공유 화면, 협업규격 4.2 5번) 그 버튼으로 시험한다.
  // 값은 흐름만 바꿀 수 있어 여기서 직접 켤 수 없다.
  test('공유 관문: P에서 확인하기 전에는 SHARE에서도 shareSend가 잠긴다 (검토 결론 5장)', () {
    final flow = testFlow()..screen = ScreenId.share;
    expect(flow.shareConfirmed, isFalse);
    expect(flow.allows(ActionId.shareSend), isFalse);
  });
}
