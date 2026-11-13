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

  // 단위 3: GuideFlow의 관문이 표를 그대로 쓰는지 (상태 잠금이 없을 때).
  test('GuideFlow 관문 = 표 결과 (모든 화면, shareSend 제외)', () {
    final flow = testFlow();
    for (final s in ScreenId.values) {
      flow.screen = s;
      final fromTable = {...StageTable.always, ...StageTable.allowedOn(s)}
        ..remove(ActionId.shareSend); // 확인 전이라 잠김 (아래 시험)
      expect(flow.allowed, fromTable, reason: s.code);
    }
  });

  test('홈(navHome)은 마무리(DONE)와 오류(E)에서만 열린다 (시스템설계 3-7·3-9)', () {
    final flow = testFlow();
    final opened = [
      for (final s in ScreenId.values)
        if ((flow..screen = s).allows(ActionId.navHome)) s,
    ];
    expect(opened, [ScreenId.done, ScreenId.e]);
  });

  test('공유 관문: P에서 확인하기 전에는 SHARE에서도 shareSend가 잠긴다 (검토 결론 5장)', () {
    final flow = testFlow()..screen = ScreenId.share;
    expect(flow.allows(ActionId.shareSend), isFalse);
    flow.shareConfirmed = true;
    expect(flow.allows(ActionId.shareSend), isTrue);
  });
}
