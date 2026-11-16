import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/capture/data/app_copy_files.dart';
import 'package:screen_guide/features/capture/data/media_gallery_input.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';

import '../../../support/fake_media_library.dart';

// MediaGalleryInput: 사진 보관함(MediaLibrary)을 바꿔 끼워 권한·목록·한 장 고르기를 확인한다.
// 실제 photo_manager·권한 창은 에뮬레이터에서 확인한다.

void main() {
  late Directory base;
  late AppCopyFiles files;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('gallery_test_');
    files = AppCopyFiles(root: await Directory('${base.path}/tmp').create());
  });

  tearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });

  MediaGalleryInput gallery(FakeLibrary lib) =>
      MediaGalleryInput(files: files, library: lib);

  test(
    '권한 허용 → ok, 거부 → permissionDenied, 보관함 오류 → permissionDenied',
    () async {
      expect(await gallery(FakeLibrary()).requestAccess(), PickStatus.ok);
      expect(
        await gallery(FakeLibrary(access: false)).requestAccess(),
        PickStatus.permissionDenied,
      );
      expect(
        await gallery(FakeLibrary()..throwOnAll = StateError('x'))
            .requestAccess(),
        PickStatus.permissionDenied,
      );
    },
  );

  test('최근 목록: limit장 이하, 순서 그대로, 스크린샷 배지는 저장 폴더로', () async {
    final lib = FakeLibrary(
      items: [
        item('a', path: 'Pictures/Screenshots/', minute: 3),
        item('b', path: 'DCIM/Camera/', minute: 2),
        item('c', path: 'DCIM/Screenshots', minute: 1),
        item('d', minute: 0),
      ],
    );
    final list = await gallery(lib).recent(limit: 3);
    expect(list.map((e) => e.id), ['a', 'b', 'c']);
    expect(list.map((e) => e.kind), [
      GalleryKind.screenshot,
      GalleryKind.photo,
      GalleryKind.screenshot,
    ]);
    expect(list.first.takenAt, DateTime(2026, 11, 13, 12, 3));
  });

  test('스크린샷 판단은 폴더 이름 전체가 Screenshots일 때만', () {
    expect(
      MediaGalleryInput.kindOf('Pictures/screenshots/'),
      GalleryKind.screenshot,
    );
    expect(
      MediaGalleryInput.kindOf('Pictures/MyScreenshotsBackup/'),
      GalleryKind.photo,
    );
    expect(MediaGalleryInput.kindOf(null), GalleryKind.photo);
  });

  test('권한이 없거나 보관함 오류면 빈 목록 (예외 없음), limit 0이면 빈 목록', () async {
    expect(
      await gallery(FakeLibrary(access: false, items: [item('a')])).recent(),
      isEmpty,
    );
    expect(
      await gallery(
        FakeLibrary(items: [item('a')])..throwOnAll = StateError('x'),
      ).recent(),
      isEmpty,
    );
    expect(
      await gallery(FakeLibrary(items: [item('a')])).recent(limit: 0),
      isEmpty,
    );
  });

  test('한 장 고르기 → 앱 복사본(sg_) 경로, 내용 그대로, 갤러리 입력', () async {
    final lib = FakeLibrary(
      items: [item('a')],
      originals: {
        'a': MediaOriginal(
          name: 'Screenshot_20261113.png',
          bytes: Uint8List.fromList([7, 8, 9]),
        ),
      },
    );
    final r = await gallery(lib).use('a');
    expect(r.status, PickStatus.ok);
    expect(r.input, InputKind.gallery);
    expect(files.isAppCopy(r.path!), isTrue);
    expect(r.path, endsWith('Screenshot_20261113.png'));
    expect(await File(r.path!).readAsBytes(), [7, 8, 9]);
  });

  test('파일 이름의 특수 문자는 바꾸고, 이름이 없으면 image', () async {
    final lib = FakeLibrary(
      originals: {
        'a': MediaOriginal(name: '../사진 1.jpg', bytes: Uint8List.fromList([1])),
        'b': MediaOriginal(name: '', bytes: Uint8List.fromList([1])),
      },
    );
    final a = await gallery(lib).use('a');
    expect(
      files.isAppCopy(a.path!),
      isTrue,
      reason: '이름 때문에 sg_ 폴더 밖으로 나가지 않는다',
    );
    final b = await gallery(lib).use('b');
    expect(b.path, endsWith('image'));
  });

  test('모르는 id·빈 사진·보관함 오류 → readFailed, 경로 없음, 복사본도 남지 않음', () async {
    final lib = FakeLibrary(
      originals: {'empty': MediaOriginal(name: 'x.jpg', bytes: Uint8List(0))},
    );
    for (final id in ['none', 'empty']) {
      final r = await gallery(lib).use(id);
      expect(r.status, PickStatus.readFailed, reason: id);
      expect(r.path, isNull);
    }
    final r = await gallery(FakeLibrary()..throwOnAll = StateError('x'))
        .use('a');
    expect(r.status, PickStatus.readFailed);
    expect(files.root.listSync(), isEmpty);
  });
}
