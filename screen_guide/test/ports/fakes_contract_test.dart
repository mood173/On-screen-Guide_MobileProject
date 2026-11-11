import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/capture/data/fake_input.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/guidance_map/data/demo_guidance.dart';
import 'package:screen_guide/features/history/data/in_memory_history_repository.dart';
import 'package:screen_guide/features/share/data/fake_sharer.dart';
import 'package:screen_guide/features/share/domain/sharer.dart';

import 'port_contracts.dart';

Future<Uint8List> _noThumb(String _) async => Uint8List(0);

// 지금 쓰는 가짜 구현이 포트 공용 시험을 통과하는지. 진짜 구현도 같은 시험을 통과해야 교체한다.
void main() {
  guidanceRepositoryContract('체험용', () => const DemoGuidanceRepository());
  historyRepositoryContract('메모리', InMemoryHistoryRepository.new);
  galleryInputContract('가짜', () => FakeGalleryInput(loadThumbnail: _noThumb));
  galleryInputContract(
    '가짜(권한 거부)',
    () => FakeGalleryInput(
      access: PickStatus.permissionDenied,
      loadThumbnail: _noThumb,
    ),
  );
  cameraInputContract('가짜(성공)', FakeCameraInput.new);
  cameraInputContract(
    '가짜(취소)',
    () => FakeCameraInput(status: PickStatus.cancelled),
  );
  inputCleanupContract('가짜', FakeInputCleanup.new);
  sharerContract('가짜(보냄)', FakeSharer.new);
  sharerContract('가짜(닫음)', () => FakeSharer(outcome: ShareOutcome.dismissed));

  test('가짜 갤러리: 권한이 없으면 목록이 비고, 샘플은 스크린샷 배지', () async {
    final denied = FakeGalleryInput(
      access: PickStatus.permissionDenied,
      loadThumbnail: _noThumb,
    );
    expect(await denied.recent(), isEmpty);
    final g = FakeGalleryInput(loadThumbnail: _noThumb);
    final items = await g.recent();
    expect(items, isNotEmpty);
    expect(items.every((e) => e.kind == GalleryKind.screenshot), isTrue);
  });

  test('FakeSharer는 보낸 텍스트만 기억한다', () async {
    final s = FakeSharer();
    expect(await s.shareText('알림 설정 바꾸기 · 사용 방법 1단계'), ShareOutcome.sent);
    expect(s.sent.single, contains('사용 방법'));
    s.outcome = ShareOutcome.failed;
    expect(await s.shareText('두 번째'), ShareOutcome.failed);
    expect(s.sent, hasLength(1));
  });
}
