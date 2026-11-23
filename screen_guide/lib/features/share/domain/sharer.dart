/// 공유 결과. 닫음·미확인·실패를 구분해야 안내 문구가 달라진다 (협업규격_최종 3.2).
///
/// - [sent]      공유할 앱을 골랐다 (실제 전송 완료 여부는 플랫폼이 알려주지 않는다)
/// - [dismissed] 사용자가 시트를 닫았다
/// - [unknown]   플랫폼이 결과를 알려주지 않는다 → 성공으로 단정하지 않는다 (11/23 결정)
/// - [failed]    빈 글·예외 등 보내지 못했다
enum ShareOutcome { sent, dismissed, unknown, failed }

/// 포트: 사용 방법 텍스트 공유. ── 구현: 최정혁 (share_plus) / 사용: 지형주 (SHARE 화면)
///
/// 텍스트만 보낸다. 이미지를 받는 메서드는 만들지 않는다.
/// 흐름은 이 포트를 부르기 전에 반드시 P(공유 전 확인) 화면을 거친다 — 그 규칙은 GuideFlow 관문이 지킨다.
/// 닫음·실패는 예외가 아니라 [ShareOutcome]으로 돌려준다.
abstract interface class Sharer {
  Future<ShareOutcome> shareText(String text);
}
