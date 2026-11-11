/// 포트: 결과 공유. ── 제공: 팀원 3 (share_plus) / 사용: 팀원 2 (SHARE 화면)
///
/// 사용 방법 텍스트만 보낸다. 원본 이미지는 넣지 않는다 (기능·개념 정리 12.1 ⑥).
/// 이 포트를 부르기 전에 흐름은 반드시 P(공유 전 확인) 화면을 거친다 — 그 규칙은 GuideFlow Gate가 지킨다.
abstract interface class Sharer {
  /// 사용자가 공유 시트를 닫았으면 false
  Future<bool> shareText(String text);
}
