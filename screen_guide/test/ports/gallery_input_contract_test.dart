import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/capture/data/app_copy_files.dart';
import 'package:screen_guide/features/capture/data/media_gallery_input.dart';

import '../support/fake_media_library.dart';
import 'port_contracts.dart';

// 진짜 GalleryInput(MediaGalleryInput)이 포트 공용 시험을 통과하는지.
// 사진 보관함은 바꿔 끼운다. 실제 photo_manager·권한 창은 에뮬레이터에서 확인한다.
void main() {
  late Directory base;
  late AppCopyFiles files;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('gallery_contract_');
    files = AppCopyFiles(root: await Directory('${base.path}/tmp').create());
  });

  tearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });

  FakeLibrary lib({bool access = true}) => FakeLibrary(
    access: access,
    items: [for (var i = 0; i < 12; i++) item('p$i', minute: i)],
    originals: {
      for (var i = 0; i < 12; i++)
        'p$i': MediaOriginal(
          name: 'p$i.jpg',
          bytes: Uint8List.fromList([i + 1]),
        ),
    },
  );

  galleryInputContract(
    'photo_manager(허용)',
    () => MediaGalleryInput(files: files, library: lib()),
  );
  galleryInputContract(
    'photo_manager(거부)',
    () => MediaGalleryInput(files: files, library: lib(access: false)),
  );
}
