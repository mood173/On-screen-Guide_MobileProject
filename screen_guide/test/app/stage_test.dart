import 'package:flutter_test/flutter_test.dart';
import 'package:screen_guide/app/stage.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';

void main() {
  // 시스템설계_최종 3-0 표의 "화면" 칸을 그대로 옮긴 기대값.
  const expected = <Stage, Set<ScreenId>>{
    Stage.ready: {}, // 시작 화면은 화면 ID가 없다
    Stage.waiting: {ScreenId.h},
    Stage.input: {
      ScreenId.cp,
      ScreenId.c,
      ScreenId.cr,
      ScreenId.g,
      ScreenId.gs,
      ScreenId.gr,
    },
    Stage.analyze: {ScreenId.ca, ScreenId.ga},
    Stage.choose: {ScreenId.rc, ScreenId.rg},
    Stage.guide: {
      ScreenId.d1,
      ScreenId.d2,
      ScreenId.d3,
      ScreenId.d4,
      ScreenId.d5,
    },
    Stage.finish: {ScreenId.done},
    Stage.share: {ScreenId.p, ScreenId.share},
    Stage.recover: {ScreenId.deny, ScreenId.e},
    Stage.records: {ScreenId.history, ScreenId.settings},
    Stage.overlay: {
      ScreenId.lp,
      ScreenId.l,
      ScreenId.lo,
      ScreenId.lt,
      ScreenId.lx,
      ScreenId.lg1,
      ScreenId.lg2,
      ScreenId.lg3,
      ScreenId.lg4,
      ScreenId.lg5,
    },
  };

  test('화면마다 시스템설계 3-0 표의 단계로 연결된다', () {
    for (final entry in expected.entries) {
      for (final screen in entry.value) {
        expect(screen.stage, entry.key, reason: screen.code);
      }
    }
  });

  test('기대값 표가 화면 ID 전체(33개)를 한 번씩 담는다 — 빠진 화면이 없다', () {
    final all = [for (final s in expected.values) ...s];
    expect(all.length, ScreenId.values.length);
    expect(all.toSet(), ScreenId.values.toSet());
  });
}
