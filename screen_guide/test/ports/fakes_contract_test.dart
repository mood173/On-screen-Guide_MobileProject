import 'package:flutter_test/flutter_test.dart';
import 'package:screen_guide/data/demo_guidance.dart';
import 'package:screen_guide/data/fakes.dart';
import 'package:screen_guide/domain/image_input.dart';

import 'port_contracts.dart';

// 지금 쓰는 가짜 구현이 포트 공용 시험을 통과하는지. 진짜 구현도 같은 시험을 통과해야 교체한다.
void main() {
  guidanceRepositoryContract('체험용', () => const DemoGuidanceRepository());
  historyRepositoryContract('메모리', InMemoryHistoryRepository.new);
  imageInputShapeContract('가짜(성공)', FakeImageInput.new);
  imageInputShapeContract(
    '가짜(취소)',
    () => FakeImageInput(status: PickStatus.cancelled),
  );

  test('FakeImageInput은 앱 복사본만 지운다', () async {
    final input = FakeImageInput();
    final img = await input.pickFromGallery();
    expect(img.appOwned, isTrue);
    await input.release(img); // 예외 없이 끝나야 함
    await input.release(
      const PickedImage(status: PickStatus.ok, path: '/user/original.png'),
    );
  });

  test('FakeSharer는 보낸 텍스트를 기억한다', () async {
    final s = FakeSharer();
    expect(await s.shareText('알림 설정 바꾸기 · 사용 방법 1단계'), isTrue);
    expect(s.sent.single, contains('사용 방법'));
  });
}
