import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/capture/data/app_copy_files.dart';
import 'package:screen_guide/features/capture/data/file_input_cleanup.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';

// FileInputCleanup: 앱 복사본·image_picker 잔여 파일만 지우고, 예외를 밖으로 던지지 않는다.

void main() {
  late Directory base; // 앱 데이터 폴더 역할
  late Directory temp; // 앱 임시 폴더 (sg_ 복사본)
  late Directory cache; // image_picker 캐시 폴더
  late AppCopyFiles files;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('cleanup_test_');
    temp = await Directory('${base.path}/code_cache').create();
    cache = await Directory('${base.path}/cache').create();
    files = AppCopyFiles(root: temp);
  });

  tearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });

  FileInputCleanup cleanup({OpenSettings? open}) => FileInputCleanup(
    files: files,
    pickerCache: cache,
    cleanPickerCache: true,
    openSettings: open ?? () async {},
  );

  Future<String> copy() async {
    final src = File('${base.path}/src.jpg');
    await src.writeAsBytes([1, 2, 3]);
    return files.copyFrom(src.path);
  }

  Future<File> cacheFile(String name, [List<int> bytes = const []]) async {
    final f = File('${cache.path}/$name');
    await f.writeAsBytes(bytes);
    return f;
  }

  List<String> names(Directory d) => d
      .listSync()
      .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
      .toList();

  test('release: 앱 복사본 폴더를 지운다', () async {
    final p = await copy();
    await cleanup().release(
      PickedImage(status: PickStatus.ok, path: p, input: InputKind.camera),
    );
    expect(await File(p).parent.exists(), isFalse);
  });

  test('release: 사용자 원본 경로는 지우지 않는다', () async {
    final user = File('${base.path}/DCIM_original.jpg');
    await user.writeAsBytes([9]);
    await cleanup().release(
      PickedImage(
        status: PickStatus.ok,
        path: user.path,
        input: InputKind.gallery,
      ),
    );
    expect(await user.exists(), isTrue);
  });

  test('release: 경로 없는 실패 결과는 아무것도 하지 않는다', () async {
    await cleanup().release(
      const PickedImage.failed(PickStatus.cancelled, InputKind.camera),
    );
  });

  test('clearLeftovers: 남은 sg_ 복사본과 image_picker 파일(빈 파일·사진)을 지운다', () async {
    await copy();
    await copy();
    await cacheFile(
      'c38ef0c0-c7de-422d-8d28-6a2c5814f4592424015850821494502.jpg',
    );
    await cacheFile('e8dbfc18-e6a9-44b4-a379-3421687c6c29.JPEG', [1, 2]);

    await cleanup().clearLeftovers();

    expect(names(temp).where((n) => n.startsWith('sg_')), isEmpty);
    expect(names(cache), isEmpty);
  });

  test('clearLeftovers: image_picker 모양이 아닌 캐시 파일·하위 폴더는 남긴다', () async {
    await cacheFile('flutter_engine_cache.bin', [1]);
    await cacheFile('photo.jpg', [1]);
    await cacheFile('c38ef0c0-c7de-422d-8d28-6a2c5814f459.txt', [1]);
    final sub = await Directory('${cache.path}/image_picker_sub').create();
    final inSub = File('${sub.path}/c38ef0c0-c7de-422d-8d28-6a2c5814f459.jpg');
    await inSub.writeAsBytes([1]);

    await cleanup().clearLeftovers();

    expect(names(cache)..sort(), [
      'c38ef0c0-c7de-422d-8d28-6a2c5814f459.txt',
      'flutter_engine_cache.bin',
      'image_picker_sub',
      'photo.jpg',
    ]);
    expect(await inSub.exists(), isTrue);
  });

  test(
    'clearLeftovers: image_picker 정리를 끄면 캐시는 건드리지 않는다 (Android가 아닐 때 기본)',
    () async {
      final f = await cacheFile('c38ef0c0-c7de-422d-8d28-6a2c5814f459.jpg');
      await FileInputCleanup(
        files: files,
        pickerCache: cache,
        cleanPickerCache: false,
      ).clearLeftovers();
      expect(await f.exists(), isTrue);
    },
  );

  test('clearLeftovers: 캐시 폴더가 없어도 예외 없음', () async {
    await cache.delete(recursive: true);
    await cleanup().clearLeftovers();
  });

  test('openAppSettings: 설정 열기 함수를 부른다', () async {
    var opened = 0;
    await cleanup(open: () async => opened++).openAppSettings();
    expect(opened, 1);
  });

  test('openAppSettings: 열지 못해도 예외가 밖으로 나가지 않는다', () async {
    await cleanup(open: () async => throw StateError('no activity'))
        .openAppSettings();
  });

  test('기본 image_picker 캐시 위치는 임시 폴더 옆 cache', () {
    final c = FileInputCleanup(files: files, openSettings: () async {});
    expect(
      c.pickerCache.path.replaceAll(r'\', '/'),
      '${base.path.replaceAll(r'\', '/')}/cache',
    );
  });
}
