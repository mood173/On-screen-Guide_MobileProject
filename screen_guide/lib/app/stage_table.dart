import 'package:screen_guide/app/stage.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';

/// 한 단계의 관문 규칙 (시스템설계_최종 3-1 "허용 버튼").
class StageRule {
  const StageRule({required this.allowed, this.byScene = const {}});

  /// 단계 기본: 시스템설계_최종 3장 각 표의 "허용 버튼" 줄 그대로.
  final Set<ActionId> allowed;

  /// 장면별로 좁히기. 여기 적힌 화면은 [allowed] 대신 이 목록을 쓴다.
  /// 예: 입력 단계라도 G(목록)에서는 아직 고른 이미지가 없으니 `analyzeRun`을 열지 않는다.
  /// 장면 목록은 반드시 단계 기본의 일부여야 한다 (시험으로 확인).
  final Map<ScreenId, Set<ActionId>> byScene;

  /// 이 화면에서 허용하는 버튼: 장면 목록이 있으면 그것, 없으면 단계 기본.
  Set<ActionId> allowedOn(ScreenId screen) => byScene[screen] ?? allowed;
}

/// 단계 설정표 (시스템설계_최종 3-1~3-9, 6-2의 `StageTable`).
///
/// 지금은 "허용 버튼"만 담는다. 화면 틀(셸·진행 칸·뒤로)은 단위 4, 들어갈 때·나갈 때 할 일은 단위 5에서 더한다.
class StageTable {
  StageTable._(); // 표만 담는 곳이라 객체를 만들지 않는다.

  /// 어느 단계에서든 허용: 뒤로·홈. (지금 GuideFlow의 `_always`와 같다)
  static const always = {ActionId.navBack, ActionId.navHome};

  static const rules = <Stage, StageRule>{
    // 3-2 준비: 앱 시작 중이라 누를 버튼이 없다.
    Stage.ready: StageRule(allowed: {}),

    // 3-2 대기 (H)
    Stage.waiting: StageRule(
      allowed: {
        ActionId.captureGallery,
        ActionId.captureCamera,
        ActionId.overlaySetup,
        ActionId.navHistory,
        ActionId.navSettings,
      },
    ),

    // 3-3 입력. 문서는 단계 전체를 한 줄로 적었고, 장면마다 지금 할 수 있는 것만 연다.
    Stage.input: StageRule(
      allowed: {
        ActionId.captureGallery,
        ActionId.captureCamera,
        ActionId.capturePick,
        ActionId.captureConfirm,
        ActionId.captureRetake,
        ActionId.analyzeRun,
      },
      byScene: {
        // 갤러리 — 지금 GuideFlow._gate와 같다.
        ScreenId.g: {ActionId.capturePick},
        ScreenId.gs: {
          ActionId.capturePick,
          ActionId.captureConfirm,
          ActionId.captureRetake,
        },
        ScreenId.gr: {ActionId.analyzeRun, ActionId.captureRetake},
        // 카메라 — 문서에 장면별 표가 없어 갤러리와 같은 모양으로 정함 (11/14 결정). 카메라 화면을 만들 때 다시 본다.
        ScreenId.cp: {ActionId.captureCamera}, // 권한 설명 → 촬영
        ScreenId.c: {}, // 기기 기본 카메라가 대신하는 동안 누를 것 없음
        ScreenId.cr: {ActionId.analyzeRun, ActionId.captureRetake},
      },
    ),

    // 3-4 분석: 취소 하나. 다시 요청은 받지 않는다 (중복 분석 차단).
    Stage.analyze: StageRule(allowed: {ActionId.analyzeCancel}),

    // 3-5 선택: 저장·공유는 열지 않는다 (기능별_검토_결론 13장 X1).
    Stage.choose: StageRule(
      allowed: {ActionId.guideStart, ActionId.captureRetake},
    ),

    // 3-6 안내. "대상을 찾는 중에는 셋 다 잠금"은 표가 아니라 흐름의 상태(locating)라 GuideFlow에 남긴다.
    Stage.guide: StageRule(
      allowed: {ActionId.guideNext, ActionId.guidePrev, ActionId.guideMismatch},
    ),

    // 3-7 마무리
    Stage.finish: StageRule(
      allowed: {ActionId.historySave, ActionId.sharePrepare, ActionId.navHome},
    ),

    // 3-8 공유. shareSend는 SHARE 장면에만 → P(확인)를 거치지 않고는 보낼 수 없다.
    Stage.share: StageRule(
      allowed: {ActionId.shareConfirm, ActionId.shareSend, ActionId.navBack},
      byScene: {
        ScreenId.p: {ActionId.shareConfirm, ActionId.navBack},
        ScreenId.share: {ActionId.shareSend, ActionId.navBack},
      },
    ),

    // 3-9 복구: 장면마다 버튼이 다르다.
    Stage.recover: StageRule(
      allowed: {
        ActionId.settingsOpenPermission,
        ActionId.captureGallery,
        ActionId.captureRetake,
        ActionId.captureCamera,
        ActionId.navHome,
      },
      byScene: {
        ScreenId.deny: {
          ActionId.settingsOpenPermission,
          ActionId.captureGallery,
        },
        ScreenId.e: {
          ActionId.captureRetake,
          ActionId.captureCamera,
          ActionId.captureGallery,
          ActionId.navHome,
        },
      },
    ),

    // 3-9 기록·설정. 문서는 두 화면을 한 줄로 적었지만, 화면에 없는 버튼이 열리지 않게 장면별로 나눈다 (11/14 결정).
    Stage.records: StageRule(
      allowed: {
        ActionId.historyOpen,
        ActionId.historyDelete,
        ActionId.sharePrepare,
        ActionId.syncToggle,
        ActionId.settingsOpenPermission,
      },
      byScene: {
        ScreenId.history: {
          ActionId.historyOpen,
          ActionId.historyDelete,
          ActionId.sharePrepare,
        },
        ScreenId.settings: {
          ActionId.syncToggle,
          ActionId.settingsOpenPermission,
        },
      },
    ),

    // 실시간 안내 (N01, 일정 제외): 자리만 둔다. 하게 되면 이 줄을 채운다.
    Stage.overlay: StageRule(allowed: {}),
  };

  /// 이 화면에서 허용하는 버튼 (뒤로·홈 제외).
  /// 모든 단계가 [rules]에 있다는 것은 시험이 확인하므로 `!`를 쓴다.
  static Set<ActionId> allowedOn(ScreenId screen) =>
      rules[screen.stage]!.allowedOn(screen);
}
