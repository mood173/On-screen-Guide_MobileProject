import 'package:screen_guide/shared/contracts/screen_id.dart';

/// 실행 흐름의 단계 (시스템설계_최종 3-0).
///
/// 단계 = "사용자가 지금 하는 일", 화면 = 그 단계 안의 한 장면.
/// 관문(허용 버튼)·화면 틀·들어갈 때/나갈 때 할 일은 단계를 기준으로 정한다 (3-1 단계 설정표).
enum Stage {
  ready, // 준비: 앱 시작. 화면 ID가 없다 (시작 화면)
  waiting, // 대기: 무엇을 할지 고른다
  input, // 입력: 화면을 찍거나 고른다
  analyze, // 분석: 기다린다 (취소 가능)
  choose, // 선택: 결과를 보고 기능을 고른다
  guide, // 안내: 짚어 준 곳을 누르고 다음으로
  finish, // 마무리: 저장하거나 끝낸다
  share, // 공유: 개인정보 후보를 확인하고 보낸다
  recover, // 복구: 다시 시도할 방법을 고른다
  records, // 기록·설정
  overlay, // 실시간 안내 (N01, 확장). 3장 표에 없음 — 일정 제외라 허용 버튼 없이 자리만 둔다
}

/// 화면 → 단계 연결 (시스템설계_최종 6-2의 `ScreenId.stage`).
///
/// screen_id.dart는 공동 폴더(shared/contracts/)라 고치지 않고,
/// 지형주 폴더(app/)에서 extension으로 붙인다 (협업규격_최종 2장).
extension ScreenStage on ScreenId {
  Stage get stage {
    // default를 두지 않는다: 화면 ID가 새로 생기면 여기서 컴파일 오류가 나서 빠뜨리지 않는다.
    switch (this) {
      case ScreenId.h:
        return Stage.waiting;

      // C(촬영)는 기기 기본 카메라가 대신하지만 입력 단계의 장면이다.
      case ScreenId.cp:
      case ScreenId.c:
      case ScreenId.cr:
      case ScreenId.g:
      case ScreenId.gs:
      case ScreenId.gr:
        return Stage.input;

      case ScreenId.ca:
      case ScreenId.ga:
        return Stage.analyze;

      case ScreenId.rc:
      case ScreenId.rg:
        return Stage.choose;

      case ScreenId.d1:
      case ScreenId.d2:
      case ScreenId.d3:
      case ScreenId.d4:
      case ScreenId.d5:
        return Stage.guide;

      case ScreenId.done:
        return Stage.finish;

      // 마무리·기록 어디서 들어와도 같은 공유 단계 (3-8).
      case ScreenId.p:
      case ScreenId.share:
        return Stage.share;

      case ScreenId.deny:
      case ScreenId.e:
        return Stage.recover;

      case ScreenId.history:
      case ScreenId.settings:
        return Stage.records;

      case ScreenId.lp:
      case ScreenId.l:
      case ScreenId.lo:
      case ScreenId.lt:
      case ScreenId.lx:
      case ScreenId.lg1:
      case ScreenId.lg2:
      case ScreenId.lg3:
      case ScreenId.lg4:
      case ScreenId.lg5:
        return Stage.overlay;
    }
  }
}
