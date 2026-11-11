/// UI 행동 ID — 화면의 버튼이 내보내는 것. (개발 계약 v1 결정 2 + 협업규격_최종 3.5, 28개)
///
/// "ID 하나 = 뜻 하나". 새 버튼이 생기면 협업규격 3.5 표에 먼저 추가하고 세 명이 확인한 뒤 여기에 반영한다.
/// 안내 대상 앱의 기능 ID("settings.notification" 같은 영역.동작 문자열)와는 다르다.
/// ★ = 계약 v1의 23개에 더한 5개 (기능별_검토_결론 9-2)
enum ActionId {
  // 입력 (F01)
  captureCamera,
  captureGallery, // 갤러리 열기
  capturePick, // ★ 목록 한 칸 누르기 (인자: GalleryItem.id)
  captureConfirm, // ★ 선택한 이미지 사용
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
  historyOpen, // 기록 한 건 열기 (인자: HistoryEntry.id)
  historyDelete, // ★ 기록 한 건 지우기 (인자: HistoryEntry.id)
  syncToggle,
  // 설정·권한·이동
  settingsOpenPermission, // 기기의 앱 권한 설정 열기
  navHome,
  navBack,
  navHistory, // ★ 기록 화면으로
  navSettings, // ★ 설정 화면으로
  // 기능 맵 (B01·B02, 시스템)
  mapCheck,
  // 오버레이 (N01, 5단계)
  overlaySetup,
  overlayStart,
  overlayStop,
  overlayRescan,
}
