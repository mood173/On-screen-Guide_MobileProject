// 최정혁(데이터·입출력)이 진짜 구현을 넣기 전까지 쓰는 가짜 구현. app/bootstrap.dart에서 진짜로 바꿔 끼운다.
// ignore_for_file: prefer_initializing_formals

import 'package:screen_guide/features/capture/data/image_files.dart';
import 'package:screen_guide/features/capture/data/sample_images.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';

/// 가짜 사진 가져오기: 갤러리·카메라 모두 [sample]을 앱 복사본으로 돌려준다.
/// [status]를 바꾸면 취소·권한 거부·읽기 실패 화면을 시험할 수 있다.
class FakeImageInput implements ImageInput {
  FakeImageInput({
    ImageFiles files = const AssetPathImageFiles(),
    this.sample = SampleImage.settings,
    this.status = PickStatus.ok,
  }) : _files = files;

  final ImageFiles _files;
  SampleImage sample;
  PickStatus status;

  Future<PickedImage> _pick(String input) async {
    if (status != PickStatus.ok) return PickedImage.failed(status);
    final path = await _files.prepare(sample);
    return PickedImage(
      status: PickStatus.ok,
      path: path,
      input: input,
      appOwned: true,
    );
  }

  @override
  Future<PickedImage> pickFromGallery() => _pick('gallery');

  @override
  Future<PickedImage> takePhoto() => _pick('camera');

  @override
  Future<void> release(PickedImage image) async {
    if (image.appOwned && image.path != null) await _files.release(image.path!);
  }
}
