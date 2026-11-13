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

  // 단위 3에서 GuideFlow가 이 표를 보게 바꿔도 동작이 같은지 미리 확인한다.
  // 지금 GuideFlow._gate에 적힌 화면들만 비교한다 (나머지 화면은 아직 만들어지지 않음).
  test('지금 GuideFlow 관문과 같은 결과를 낸다', () {
    const gated = [
      ScreenId.h,
      ScreenId.g,
      ScreenId.gs,
      ScreenId.gr,
      ScreenId.ga,
      ScreenId.rg,
      ScreenId.d1,
      ScreenId.d2,
      ScreenId.d3,
      ScreenId.d4,
      ScreenId.d5,
      ScreenId.done,
      ScreenId.e,
    ];
    final flow = testFlow();
    for (final s in gated) {
      flow.screen = s;
      expect(
        {...StageTable.always, ...StageTable.allowedOn(s)},
        flow.allowed,
        reason: s.code,
      );
    }
  });
}
