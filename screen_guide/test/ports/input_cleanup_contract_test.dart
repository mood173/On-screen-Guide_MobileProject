import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/capture/data/app_copy_files.dart';
import 'package:screen_guide/features/capture/data/file_input_cleanup.dart';

import 'port_contracts.dart';

// 진짜 InputCleanup(FileInputCleanup)이 포트 공용 시험을 통과하는지.
// 설정 화면 열기는 실제 기기가 필요해 함수로 바꿔 끼운다. 실제 화면은 에뮬레이터에서 확인한다.
void main() {
  late Directory base;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('cleanup_contract_');
  });

  tearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });

  inputCleanupContract(
    '앱 복사본 + image_picker 캐시',
    () => FileInputCleanup(
      files: AppCopyFiles(root: Directory('${base.path}/tmp')..createSync()),
      pickerCache: Directory('${base.path}/cache'),
      cleanPickerCache: true,
      openSettings: () async {},
    ),
  );
}
