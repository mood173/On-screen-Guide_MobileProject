import 'package:screen_guide/app/stage.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';

/// 화면 틀 (시스템설계_최종 4-1 셸 4개 + 준비 단계의 시작 화면).
enum Shell {
  start, // 준비: 시작 화면 (3-2). 화면 ID가 없어 지금은 쓰는 곳 없음
  app, // 앱 셸: 제목 + 본문 + 하단 탭 3개 (대기, 기록·설정)
  guide, // 안내 셸: 툴바 + 진행 표시 5칸 + 본문 + 하단 버튼 (입력 ~ 마무리, 복구)
  share, // 공유 셸: 툴바 + 본문 + 하단 버튼, 진행 표시 없음
  overlay, // 오버레이 셸 (N01, 확장): Kotlin이 다른 앱 위에 그림
}

/// 한 단계의 규칙: 관문(허용 버튼)과 화면 틀 (시스템설계_최종 3-1).
class StageRule {
  const StageRule({
    required this.shell,
    this.progress,
    required this.allowed,
    this.byScene = const {},
  });

  /// 이 단계가 쓰는 화면 틀.
  final Shell shell;

  /// 진행 표시 5칸 중 몇 번째인가 (1 입력 ~ 5 완료). 진행 표시가 없는 단계는 null.
  /// 복구는 "실패한 단계에 멈춤"(3-9)이라 표에 고정할 수 없어 null — GuideFlow.progress가 정한다.
  final int? progress;

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
/// 담는 것: 허용 버튼, 화면 틀(셸·진행 칸).
/// 들어갈 때·나갈 때 할 일은 흐름의 값을 바꿔야 해서 표가 아니라 GuideFlow._onEnter/_onExit에 둔다.
///
/// 뒤로 가기는 표에 넣지 않는다 (11/14 결정, 3-1·3-3과 다름).
/// 문서는 단계 단위("입력: 뒤로 = 대기")로 적었지만, 실제로는 장면마다 한 칸씩 돌아가야 한다
/// (GR → GS → G → 홈). 그래서 뒤로는 GuideFlow._back이 장면별로 정한다.
/// 문서와의 대응: 단계의 첫 장면에서 뒤로 = 문서의 "뒤로" (입력 G → 대기, 분석 → 취소).
/// 공유의 "뒤로 = 들어온 단계"(3-8)는 아직 없다 — 공유 화면을 만들 때 _back에 넣는다.
class StageTable {
  StageTable._(); // 표만 담는 곳이라 객체를 만들지 않는다.

  /// 어느 단계에서든 허용: 뒤로. 어디로 가는지는 GuideFlow._back이 장면별로 정한다 (위 설명).
  /// 홈(`navHome`)은 넣지 않는다: 문서 3장이 마무리(3-7)와 오류 E(3-9)에만 적었고,
  /// 분석 중(3-4)은 "analyzeCancel 하나"다 (11/14 결정, 골격의 "어디서나 홈"에서 바꿈).
  /// 앱 셸의 하단 탭(홈·기록·설정)은 아래 [appShellTabs]로 셸이 연다.
  static const always = {ActionId.navBack};

  /// 앱 셸의 하단 탭 3개 (3-2, 4-1). 단계의 버튼이 아니라 틀이 주는 버튼이라 따로 둔다.
  /// 3-9 기록·설정 표에는 탭이 없지만, 앱 셸 안에 있으므로 탭으로 오가야 한다.
  static const appShellTabs = {
    ActionId.navHome,
    ActionId.navHistory,
    ActionId.navSettings,
  };

  /// 단계 → 규칙. Map이 아니라 switch라서 단계가 하나라도 빠지면 컴파일되지 않는다
  /// (단계 연결·훅·결과 변환과 같은 원칙, default 없음).
  static StageRule ruleFor(Stage stage) => switch (stage) {
    // 3-2 준비: 앱 시작 중이라 누를 버튼이 없다.
    Stage.ready => const StageRule(shell: Shell.start, allowed: {}),

    // 3-2 대기 (H)
    Stage.waiting => const StageRule(
      shell: Shell.app,
      allowed: {
        ActionId.captureGallery,
        ActionId.captureCamera,
        ActionId.overlaySetup,
        ActionId.navHistory,
        ActionId.navSettings,
      },
    ),

    // 3-3 입력. 문서는 단계 전체를 한 줄로 적었고, 장면마다 지금 할 수 있는 것만 연다.
    Stage.input => const StageRule(
      shell: Shell.guide,
      progress: 1, // "입력"
      allowed: {
        ActionId.captureGallery,
        ActionId.captureCamera,
        ActionId.capturePick,
        ActionId.captureConfirm,
        ActionId.captureRetake,
        ActionId.analyzeRun,
      },
      byScene: {
        // 갤러리 — 골격의 화면별 관문 표와 같다.
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
    Stage.analyze => const StageRule(
      shell: Shell.guide,
      progress: 2, // "분석"
      allowed: {ActionId.analyzeCancel},
    ),

    // 3-5 선택: 저장·공유는 열지 않는다 (기능별_검토_결론 13장 X1).
    Stage.choose => const StageRule(
      shell: Shell.guide,
      progress: 3, // "기능 선택"
      allowed: {ActionId.guideStart, ActionId.captureRetake},
    ),

    // 3-6 안내. "대상을 찾는 중에는 셋 다 잠금"은 표가 아니라 흐름의 상태(locating)라 GuideFlow에 남긴다.
    Stage.guide => const StageRule(
      shell: Shell.guide,
      progress: 4, // "안내" (단계 n/N은 화면이 따로 그린다)
      allowed: {ActionId.guideNext, ActionId.guidePrev, ActionId.guideMismatch},
    ),

    // 3-7 마무리
    Stage.finish => const StageRule(
      shell: Shell.guide,
      progress: 5, // "완료"
      allowed: {ActionId.historySave, ActionId.sharePrepare, ActionId.navHome},
    ),

    // 3-8 공유. shareSend는 SHARE 장면에만 연다.
    // 표만으로는 "P를 거쳤는가"를 알 수 없다 (SHARE로 바로 가는 길이 생기면 뚫림).
    // 기능별_검토_결론 5장 관문(필수): 세션의 "확인함" 값이 켜져 있을 때만 shareSend — 흐름 상태라 GuideFlow에서 확인한다.
    Stage.share => const StageRule(
      shell: Shell.share,
      allowed: {ActionId.shareConfirm, ActionId.shareSend, ActionId.navBack},
      byScene: {
        ScreenId.p: {ActionId.shareConfirm, ActionId.navBack},
        ScreenId.share: {ActionId.shareSend, ActionId.navBack},
      },
    ),

    // 3-9 복구: 장면마다 버튼이 다르다.
    Stage.recover => const StageRule(
      shell: Shell.guide, // 진행 칸은 실패한 단계 것 (GuideFlow.progress)
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
    Stage.records => const StageRule(
      shell: Shell.app,
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
    Stage.overlay => const StageRule(shell: Shell.overlay, allowed: {}),
  };

  /// 이 화면이 속한 단계의 규칙.
  static StageRule ruleOf(ScreenId screen) => ruleFor(screen.stage);

  /// 이 화면에서 허용하는 버튼 (뒤로 제외): 단계(장면)의 버튼 + 앱 셸이면 하단 탭.
  static Set<ActionId> allowedOn(ScreenId screen) {
    final rule = ruleOf(screen);
    return {
      ...rule.allowedOn(screen),
      if (rule.shell == Shell.app) ...appShellTabs,
    };
  }
}
