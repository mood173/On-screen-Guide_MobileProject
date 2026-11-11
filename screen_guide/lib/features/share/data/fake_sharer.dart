// 최정혁(데이터·입출력)이 진짜 구현을 넣기 전까지 쓰는 가짜 구현. app/bootstrap.dart에서 진짜로 바꿔 끼운다.

import 'package:screen_guide/features/share/domain/sharer.dart';

/// 가짜 공유: 보낸 텍스트를 기억만 한다.
class FakeSharer implements Sharer {
  final sent = <String>[];

  @override
  Future<bool> shareText(String text) async {
    sent.add(text);
    return true;
  }
}
