import 'package:share_plus/share_plus.dart';

import 'package:screen_guide/features/share/domain/sharer.dart';

/// 텍스트를 시스템 공유 시트로 보내고 결과 상태를 돌려주는 함수. 시험에서 바꿔 끼운다.
typedef ShareTextSheet = Future<ShareResultStatus> Function(String text);

Future<ShareResultStatus> _shareWithSharePlus(String text) async =>
    (await SharePlus.instance.share(ShareParams(text: text))).status;

/// [Sharer]의 진짜 구현. ── 최정혁 (협업규격_최종 4.3 #7)
///
/// Android 시스템 공유 시트(`share_plus`)로 **텍스트만** 보낸다. 이미지·파일을 받는 메서드는 없다.
/// 공유 전 확인(P) 화면을 거쳤는지는 흐름의 관문이 지킨다. 이 구현은 받은 텍스트를 보내기만 한다.
///
/// | share_plus 결과 | [ShareOutcome] |
/// |---|---|
/// | `success` (사용자가 앱을 고름) | `sent` |
/// | `dismissed` (시트를 닫음) | `dismissed` |
/// | `unavailable` (시트는 열렸지만 결과를 알 수 없음) | `sent` [제안 — 팀 확인] |
/// | 빈 텍스트, 예외 | `failed` |
///
/// Android는 "앱을 골랐다"까지만 알려 준다. 고른 앱에서 실제로 보냈는지는 알 수 없다.
/// 예외를 밖으로 던지지 않는다.
class SharePlusSharer implements Sharer {
  SharePlusSharer({ShareTextSheet? sheet})
    : _sheet = sheet ?? _shareWithSharePlus;

  final ShareTextSheet _sheet;

  @override
  Future<ShareOutcome> shareText(String text) async {
    if (text.trim().isEmpty) return ShareOutcome.failed;
    try {
      return outcomeOf(await _sheet(text));
    } catch (_) {
      return ShareOutcome.failed;
    }
  }

  static ShareOutcome outcomeOf(ShareResultStatus status) => switch (status) {
    ShareResultStatus.success => ShareOutcome.sent,
    ShareResultStatus.dismissed => ShareOutcome.dismissed,
    ShareResultStatus.unavailable => ShareOutcome.sent,
  };
}
