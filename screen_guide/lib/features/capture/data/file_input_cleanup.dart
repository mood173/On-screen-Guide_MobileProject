import 'dart:io';

import 'package:app_settings/app_settings.dart';

import 'package:screen_guide/features/capture/data/app_copy_files.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';

/// 기기의 앱 권한 설정 화면을 여는 함수. 시험에서 바꿔 끼우려고 함수로 받는다.
typedef OpenSettings = Future<void> Function();

Future<void> _openWithAppSettings() => AppSettings.openAppSettings();

/// [InputCleanup]의 진짜 구현. ── 최정혁 (협업규격_최종 4.3 #4)
///
/// | 메서드 | 하는 일 |
/// |---|---|
/// | [release] | 앱 복사본(`sg_` 폴더)만 지운다. 사용자 원본·경로 없는 결과는 아무것도 하지 않는다 |
/// | [clearLeftovers] | 앱 시작 때 남은 `sg_` 복사본과, image_picker가 앱 캐시에 남긴 사진 파일을 지운다 |
/// | [openAppSettings] | 기기의 앱 정보(권한) 화면을 연다 (`app_settings` 패키지) |
///
/// 모든 메서드는 예외를 밖으로 던지지 않는다 (협업규격_최종 3장 공통규칙 1).
///
/// 설정 화면은 Kotlin 채널을 새로 만들지 않고 패키지로 연다.
/// 규격 2장 "Kotlin을 부르는 Dart 코드는 MethodChannelAnalyzer 하나뿐"을 지키기 위해서다.
class FileInputCleanup implements InputCleanup {
  FileInputCleanup({
    AppCopyFiles? files,
    Directory? pickerCache,
    bool? cleanPickerCache,
    OpenSettings? openSettings,
  }) : _files = files ?? AppCopyFiles(),
       _pickerCacheOverride = pickerCache,
       _cleanPickerCache = cleanPickerCache ?? Platform.isAndroid,
       _openSettings = openSettings ?? _openWithAppSettings;

  final AppCopyFiles _files;
  final Directory? _pickerCacheOverride;
  final bool _cleanPickerCache;
  final OpenSettings _openSettings;

  /// image_picker가 촬영 파일을 만드는 앱 캐시 폴더.
  /// Android에서 임시 폴더는 `/data/user/0/<앱>/code_cache`라, 그 옆의 `cache`다.
  Directory get pickerCache =>
      _pickerCacheOverride ??
      Directory('${_files.root.parent.path}${Platform.pathSeparator}cache');

  /// image_picker가 만드는 파일 이름: UUID 뒤에 임시 파일 숫자가 붙고 이미지 확장자로 끝난다.
  /// 예) `c38ef0c0-c7de-422d-8d28-6a2c5814f4592424015850821494502.jpg` (에뮬레이터에서 확인, 11/12)
  /// 이 모양이 아닌 파일은 다른 플러그인 것일 수 있으므로 건드리지 않는다.
  static final pickerFileName = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\d*'
    r'\.(jpe?g|png|webp|gif|heic)$',
    caseSensitive: false,
  );

  @override
  Future<void> release(PickedImage image) async {
    final path = image.path;
    if (path == null) return;
    try {
      await _files.release(path);
    } catch (_) {
      // 지우지 못한 복사본은 다음 앱 시작 때 clearLeftovers가 다시 지운다
    }
  }

  @override
  Future<void> clearLeftovers() async {
    try {
      await _files.clearLeftovers();
    } catch (_) {
      // 다음 시작 때 다시
    }
    if (_cleanPickerCache) await _clearPickerFiles();
  }

  /// 카메라를 취소하면 image_picker가 미리 만든 0바이트 파일이 남고(11/12 에뮬레이터에서 확인),
  /// 앱이 촬영 중 종료되면 사진이 든 파일이 남을 수 있다. 둘 다 앱이 만든 파일이라 지운다.
  /// 캐시 폴더 바로 아래, 이름이 image_picker 모양인 파일만 지운다 (하위 폴더는 보지 않는다).
  Future<void> _clearPickerFiles() async {
    try {
      final dir = pickerCache;
      if (!await dir.exists()) return;
      await for (final e in dir.list(followLinks: false)) {
        if (e is! File) continue;
        final name = e.uri.pathSegments.last;
        if (!pickerFileName.hasMatch(name)) continue;
        try {
          await e.delete();
        } on FileSystemException {
          // 다음 시작 때 다시
        }
      }
    } catch (_) {
      // 캐시 폴더를 읽지 못함 → 다음 시작 때 다시
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      await _openSettings();
    } catch (_) {
      // 설정 화면을 열지 못해도 흐름은 막지 않는다. 권한 안내 화면에 그대로 머문다.
    }
  }
}
