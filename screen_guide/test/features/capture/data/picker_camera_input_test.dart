import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/capture/data/app_copy_files.dart';
import 'package:screen_guide/features/capture/data/picker_camera_input.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';

// PickerCameraInput: 실제 카메라 대신 촬영 함수를 바꿔 끼워 네 가지 결과를 확인한다.
// 실제 카메라 앱·권한 대화상자는 에뮬레이터에서 따로 확인한다 (docs/cijghk/ai_log).

void main() {
  late Directory base; // 앱 데이터 폴더 역할
  late Directory temp; // 앱 임시 폴더 역할 (복사본이 생기는 곳)
  late Directory cameraCache; // image_picker가 촬영 파일을 두는 곳 역할
  late AppCopyFiles files;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('camera_test_');
    temp = await Directory('${base.path}/code_cache').create();
    cameraCache = await Directory('${base.path}/cache').create();
    files = AppCopyFiles(root: temp);
  });

  tearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });

  Future<String> shot(String name, {List<int> bytes = const [1, 2, 3]}) async {
    final f = File('${cameraCache.path}/$name');
    await f.writeAsBytes(bytes);
    return f.path;
  }

  test('촬영 성공 → ok, 앱 복사본(sg_) 경로, 카메라 입력', () async {
    final original = await shot('photo.jpg');
    final cam = PickerCameraInput(files: files, capture: () async => original);

    final r = await cam.takePhoto();

    expect(r.status, PickStatus.ok);
    expect(r.ok, isTrue);
    expect(r.input, InputKind.camera);
    expect(files.isAppCopy(r.path!), isTrue);
    expect(await File(r.path!).readAsBytes(), [1, 2, 3]);
  });

  test('성공하면 카메라가 앱 캐시에 남긴 촬영 파일은 지운다 (원본 미보관)', () async {
    final original = await shot('photo.jpg');
    final cam = PickerCameraInput(files: files, capture: () async => original);

    await cam.takePhoto();

    expect(await File(original).exists(), isFalse);
  });

  test('카메라를 닫으면 cancelled, 경로 없음', () async {
    final cam = PickerCameraInput(files: files, capture: () async => null);
    final r = await cam.takePhoto();
    expect(r.status, PickStatus.cancelled);
    expect(r.path, isNull);
    expect(r.input, InputKind.camera);
  });

  for (final code in PickerCameraInput.permissionDeniedCodes) {
    test('권한 거부 코드 $code → permissionDenied', () async {
      final cam = PickerCameraInput(
        files: files,
        capture: () async => throw PlatformException(code: code),
      );
      final r = await cam.takePhoto();
      expect(r.status, PickStatus.permissionDenied);
      expect(r.path, isNull);
    });
  }

  test('그 밖의 플랫폼 오류 → readFailed (예외가 밖으로 나가지 않는다)', () async {
    final cam = PickerCameraInput(
      files: files,
      capture: () async => throw PlatformException(code: 'no_available_camera'),
    );
    expect((await cam.takePhoto()).status, PickStatus.readFailed);
  });

  test('플랫폼 오류가 아닌 예외도 readFailed', () async {
    final cam = PickerCameraInput(
      files: files,
      capture: () async => throw StateError('알 수 없는 오류'),
    );
    expect((await cam.takePhoto()).status, PickStatus.readFailed);
  });

  test('촬영 파일이 없으면 readFailed', () async {
    final cam = PickerCameraInput(
      files: files,
      capture: () async => '${cameraCache.path}/missing.jpg',
    );
    expect((await cam.takePhoto()).status, PickStatus.readFailed);
  });

  test('빈 파일이면 readFailed, 복사본 폴더도 남지 않는다', () async {
    final empty = await shot('empty.jpg', bytes: const []);
    final cam = PickerCameraInput(files: files, capture: () async => empty);

    expect((await cam.takePhoto()).status, PickStatus.readFailed);
    expect(await temp.list().toList(), isEmpty);
  });

  test('앱 데이터 폴더 밖의 파일(사용자 원본)은 복사만 하고 지우지 않는다', () async {
    final outside = await Directory.systemTemp.createTemp('user_gallery_');
    addTearDown(() => outside.delete(recursive: true));
    final userFile = File('${outside.path}/original.jpg');
    await userFile.writeAsBytes([9, 9]);
    final cam = PickerCameraInput(
      files: files,
      capture: () async => userFile.path,
    );

    final r = await cam.takePhoto();

    expect(r.status, PickStatus.ok);
    expect(await userFile.exists(), isTrue, reason: '사용자 원본은 지우지 않는다');
  });

  test('오류 코드 변환표', () {
    expect(
      PickerCameraInput.statusForCode('camera_access_denied'),
      PickStatus.permissionDenied,
    );
    expect(
      PickerCameraInput.statusForCode('photo_access_denied'),
      PickStatus.readFailed,
      reason: '갤러리 권한 코드는 카메라 결과가 아니다',
    );
    expect(PickerCameraInput.statusForCode(''), PickStatus.readFailed);
  });
}
