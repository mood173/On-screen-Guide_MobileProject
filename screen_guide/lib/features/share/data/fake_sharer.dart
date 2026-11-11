// 최정혁(데이터·입출력)이 진짜 구현(share_plus)을 넣기 전까지 쓰는 가짜 공유. app/bootstrap.dart에서 바꿔 끼운다.

import 'package:screen_guide/features/share/domain/sharer.dart';

/// 가짜 공유: 보낸 텍스트를 기억하고 [outcome]을 돌려준다.
class FakeSharer implements Sharer {
  FakeSharer({this.outcome = ShareOutcome.sent});

  /// 바꾸면 닫음·실패 흐름을 시험할 수 있다.
  ShareOutcome outcome;
  final sent = <String>[];

  @override
  Future<ShareOutcome> shareText(String text) async {
    if (outcome == ShareOutcome.sent) sent.add(text);
    return outcome;
  }
}
