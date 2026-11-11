/// 공유 결과. 닫음과 실패를 구분해야 안내 문구가 달라진다 (협업규격_최종 3.2).
/// [제안] bool → 세 값. 11/13 팀 확인 결과에 따라 조정.
enum ShareOutcome { sent, dismissed, failed }

/// 포트: 사용 방법 텍스트 공유. ── 구현: 최정혁 (share_plus) / 사용: 지형주 (SHARE 화면)
///
/// 텍스트만 보낸다. 이미지를 받는 메서드는 만들지 않는다.
/// 흐름은 이 포트를 부르기 전에 반드시 P(공유 전 확인) 화면을 거친다 — 그 규칙은 GuideFlow 관문이 지킨다.
/// 닫음·실패는 예외가 아니라 [ShareOutcome]으로 돌려준다.
abstract interface class Sharer {
  Future<ShareOutcome> shareText(String text);
}
