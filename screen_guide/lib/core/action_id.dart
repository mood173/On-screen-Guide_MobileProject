/// UI 행동 ID — 화면의 버튼이 내보내는 것. (개발 계약 v1 · 결정 2)
///
/// 새 버튼이 생기면 계약 문서에 먼저 추가하고 팀 방에 알린 뒤 여기에 반영한다.
/// 안내 대상 앱의 기능 ID("settings.notification" 같은 영역.동작 문자열)와는 다르다.
enum ActionId {
  // 입력 (F01)
  captureCamera,
  captureGallery,
  captureRetake,
  // 분석 (F02·F03)
  analyzeRun,
  analyzeCancel,
  // 안내 (F04)
  guideStart,
  guideNext,
  guidePrev,
  guideMismatch,
  // 공유·개인정보 (F03·F06)
  sharePrepare,
  shareConfirm,
  shareSend,
  // 기록 (F05)
  historySave,
  historyOpen,
  syncToggle,
  // 설정·권한·이동
  settingsOpenPermission,
  navHome,
  navBack,
  // 기능 맵 (B01·B02, 시스템)
  mapCheck,
  // 오버레이 (N01, 5단계)
  overlaySetup,
  overlayStart,
  overlayStop,
  overlayRescan,
}
