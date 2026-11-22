import 'package:share_plus/share_plus.dart';

import 'package:screen_guide/features/share/data/share_plus_sharer.dart';

import 'port_contracts.dart';

// 진짜 Sharer(SharePlusSharer)가 공유 공용 시험을 통과하는지. 공유 시트는 바꿔 끼운다.
void main() {
  sharerContract(
    'share_plus(보냄)',
    () => SharePlusSharer(sheet: (_) async => ShareResultStatus.success),
  );
  sharerContract(
    'share_plus(닫음)',
    () => SharePlusSharer(sheet: (_) async => ShareResultStatus.dismissed),
  );
  sharerContract(
    'share_plus(오류)',
    () => SharePlusSharer(sheet: (_) async => throw StateError('x')),
  );
}
