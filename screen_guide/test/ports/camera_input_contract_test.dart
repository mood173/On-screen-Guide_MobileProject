import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/capture/data/app_copy_files.dart';
import 'package:screen_guide/features/capture/data/picker_camera_input.dart';

import 'port_contracts.dart';

// 진짜 CameraInput(PickerCameraInput)이 포트 공용 시험을 통과하는지.
// 실제 카메라 대신 촬영 함수를 바꿔 끼운다. 카메라 앱·권한 대화상자는 에뮬레이터에서 확인한다.
void main() {
  late Directory base;
  late AppCopyFiles files;
  late String shot;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('camera_contract_');
    files = AppCopyFiles(root: await Directory('${base.path}/tmp').create());
    final f = File('${base.path}/shot.jpg');
    await f.writeAsBytes([1, 2, 3]);
    shot = f.path;
  });

  tearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });

  cameraInputContract(
    'image_picker(성공)',
    () => PickerCameraInput(files: files, capture: () async => shot),
  );
  cameraInputContract(
    'image_picker(취소)',
    () => PickerCameraInput(files: files, capture: () async => null),
  );
}
