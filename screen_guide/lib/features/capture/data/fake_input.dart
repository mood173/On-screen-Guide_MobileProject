// 최정혁(데이터·입출력)이 진짜 구현(image_picker 등)을 넣기 전까지 쓰는 가짜 사진 가져오기.
// 앱에 넣어 둔 샘플 이미지를 앱 복사본으로 만들어 돌려준다. app/bootstrap.dart에서 진짜로 바꿔 끼운다.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/services.dart';

import 'package:screen_guide/features/capture/data/image_files.dart';
import 'package:screen_guide/features/capture/data/sample_images.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';

/// 미리보기 바이트를 읽는 방법. 기본은 에셋에서 읽고, 시험에서는 빈 값을 넘긴다.
typedef ThumbnailLoader = Future<Uint8List> Function(String asset);

Future<Uint8List> _assetBytes(String asset) async =>
    (await rootBundle.load(asset)).buffer.asUint8List();

/// 가짜 갤러리: 체험용 샘플을 최근 스크린샷처럼 보여 준다.
/// [access]·[useStatus]를 바꾸면 권한 거부·읽기 실패 흐름을 시험할 수 있다.
class FakeGalleryInput implements GalleryInput {
  FakeGalleryInput({
    ImageFiles files = const AssetPathImageFiles(),
    this.samples = SampleImage.all,
    this.access = PickStatus.ok,
    this.useStatus = PickStatus.ok,
    ThumbnailLoader loadThumbnail = _assetBytes,
  }) : _files = files,
       _loadThumbnail = loadThumbnail;

  final ImageFiles _files;
  final ThumbnailLoader _loadThumbnail;
  final List<SampleImage> samples;
  PickStatus access;
  PickStatus useStatus;

  @override
  Future<PickStatus> requestAccess() async => access;

  @override
  Future<List<GalleryItem>> recent({int limit = 9}) async {
    if (access != PickStatus.ok) return const [];
    return [
      for (final (i, s) in samples.take(limit).indexed)
        GalleryItem(
          id: s.id,
          thumbnail: await _loadThumbnail(s.asset),
          kind: GalleryKind.screenshot,
          takenAt: DateTime(2026, 11, 6, 12, 0).subtract(Duration(minutes: i)),
        ),
    ];
  }

  @override
  Future<PickedImage> use(String id) async {
    if (useStatus != PickStatus.ok) {
      return PickedImage.failed(useStatus, InputKind.gallery);
    }
    final s = samples.where((s) => s.id == id).firstOrNull;
    if (s == null) {
      return const PickedImage.failed(PickStatus.readFailed, InputKind.gallery);
    }
    return PickedImage(
      status: PickStatus.ok,
      path: await _files.prepare(s),
      input: InputKind.gallery,
    );
  }
}

/// 가짜 카메라: 찍은 사진 대신 [sample]을 돌려준다.
class FakeCameraInput implements CameraInput {
  FakeCameraInput({
    ImageFiles files = const AssetPathImageFiles(),
    this.sample = SampleImage.settings,
    this.status = PickStatus.ok,
  }) : _files = files;

  final ImageFiles _files;
  SampleImage sample;
  PickStatus status;

  @override
  Future<PickedImage> takePhoto() async {
    if (status != PickStatus.ok) {
      return PickedImage.failed(status, InputKind.camera);
    }
    return PickedImage(
      status: PickStatus.ok,
      path: await _files.prepare(sample),
      input: InputKind.camera,
    );
  }
}

/// 가짜 정리: 앱이 만든 복사본만 지운다 ([ImageFiles]가 sg_ 폴더만 지움).
class FakeInputCleanup implements InputCleanup {
  FakeInputCleanup({ImageFiles files = const AssetPathImageFiles()})
    : _files = files;

  final ImageFiles _files;

  /// [openAppSettings]를 부른 횟수 (시험용)
  int settingsOpened = 0;

  @override
  Future<void> release(PickedImage image) async {
    final p = image.path;
    if (p != null) await _files.release(p);
  }

  @override
  Future<void> clearLeftovers() => _files.clearLeftovers();

  @override
  Future<void> openAppSettings() async => settingsOpened++;
}
