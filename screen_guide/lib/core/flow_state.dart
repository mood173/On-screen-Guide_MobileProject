/// 안내 세션 상태. (설계 러프 · 4장 프로세스)
///
/// IDLE → PICKED → ANALYZING → IDENTIFIED → GUIDING(n) → DONE
/// 예외: DENIED, ERROR(code), CANCELLED
///
/// 상태 사이의 전이 규칙(Gate 전이표)은 GuideSequence에서 정한다. 여기에는 상태 이름만 둔다.
enum FlowState {
  idle,
  picked,
  analyzing,
  identified,
  guiding,
  done,
  denied,
  error,
  cancelled,
}
