import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'package:screen_guide/features/share/data/share_plus_sharer.dart';
import 'package:screen_guide/features/share/domain/sharer.dart';

// SharePlusSharer: 공유 시트를 바꿔 끼워 결과 변환과 예외 처리를 확인한다.
// 실제 공유 시트는 에뮬레이터에서 확인한다.

void main() {
  test(
    '결과 변환: success → sent, dismissed → dismissed, unavailable → sent',
    () async {
      for (final (status, outcome) in [
        (ShareResultStatus.success, ShareOutcome.sent),
        (ShareResultStatus.dismissed, ShareOutcome.dismissed),
        (ShareResultStatus.unavailable, ShareOutcome.sent),
      ]) {
        final s = SharePlusSharer(sheet: (_) async => status);
        expect(
          await s.shareText('알림 설정 바꾸기 · 사용 방법 1단계'),
          outcome,
          reason: '$status',
        );
      }
    },
  );

  test('받은 텍스트를 그대로 시트에 넘긴다', () async {
    final sent = <String>[];
    final s = SharePlusSharer(
      sheet: (t) async {
        sent.add(t);
        return ShareResultStatus.success;
      },
    );
    await s.shareText('메시지 보내기\n1. 메시지 입력 칸을 눌러주세요');
    expect(sent, ['메시지 보내기\n1. 메시지 입력 칸을 눌러주세요']);
  });

  test('빈 텍스트는 시트를 열지 않고 failed', () async {
    var opened = 0;
    final s = SharePlusSharer(
      sheet: (_) async {
        opened++;
        return ShareResultStatus.success;
      },
    );
    expect(await s.shareText('   '), ShareOutcome.failed);
    expect(opened, 0);
  });

  test('플랫폼 오류·그 밖의 예외는 failed (예외가 밖으로 나가지 않는다)', () async {
    expect(
      await SharePlusSharer(
        sheet: (_) async => throw PlatformException(code: 'no_activity'),
      ).shareText('x'),
      ShareOutcome.failed,
    );
    expect(
      await SharePlusSharer(sheet: (_) async => throw StateError('x'))
          .shareText('x'),
      ShareOutcome.failed,
    );
  });
}
