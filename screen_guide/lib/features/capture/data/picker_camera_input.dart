import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:screen_guide/features/capture/data/app_copy_files.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';

/// 기기 기본 카메라 앱으로 한 장을 찍고 그 파일 경로를 돌려주는 함수. 닫으면 null.
/// 시험에서 실제 카메라 대신 바꿔 끼우려고 함수로 받는다.
typedef CapturePhoto = Future<String?> Function();

Future<String?> _pickWithImagePicker() async {
  final shot = await ImagePicker().pickImage(
    source: ImageSource.camera,
    requestFullMetadata: false, // 위치 등 메타데이터를 요청하지 않는다 (개념 정리 F01)
  );
  return shot?.path;
}

/// [CameraInput]의 진짜 구현. ── 최정혁 (협업규격_최종 4.3 #2)
///
/// 기기 기본 카메라 앱을 띄워 한 장을 받고(기능별_검토_결론 1-1 ②), 앱 복사본(`sg_` 폴더)으로 만들어 돌려준다.
/// 예외를 밖으로 던지지 않는다. 결과는 [PickStatus] 네 가지로 구분한다.
///
/// | 상황 | 결과 |
/// |---|---|
/// | 촬영 성공 | ok + 앱 복사본 경로 |
/// | 카메라 앱을 닫음 | cancelled |
/// | 카메라 권한 거부 | permissionDenied |
/// | 파일 없음·빈 파일·복사 실패·그 밖의 오류 | readFailed |
///
/// 권한 거부 오류 코드는 미니프로젝트 1단계 앱(`screen_guide_test/lib/main.dart`의 `_handlePickerError`)에서
/// 에뮬레이터로 확인한 값을 그대로 쓴다.
class PickerCameraInput implements CameraInput {
  PickerCameraInput({AppCopyFiles? files, CapturePhoto? capture})
    : _files = files ?? AppCopyFiles(),
      _capture = capture ?? _pickWithImagePicker;

  final AppCopyFiles _files;
  final CapturePhoto _capture;

  /// image_picker가 카메라 권한 거부에 쓰는 오류 코드
  static const permissionDeniedCodes = {
    'camera_access_denied',
    'camera_access_denied_without_prompt',
  };

  @override
  Future<PickedImage> takePhoto() async {
    final String? shot;
    try {
      shot = await _capture();
    } on PlatformException catch (e) {
      return _failed(statusForCode(e.code));
    } catch (_) {
      return _failed(PickStatus.readFailed);
    }
    if (shot == null) return _failed(PickStatus.cancelled);

    try {
      final copy = await _files.copyFrom(shot);
      return PickedImage(
        status: PickStatus.ok,
        path: copy,
        input: InputKind.camera,
      );
    } catch (_) {
      return _failed(PickStatus.readFailed);
    } finally {
      await _deleteCameraFile(shot);
    }
  }

  /// image_picker 오류 코드 → 결과. 권한 거부가 아니면 모두 읽기 실패로 본다.
  static PickStatus statusForCode(String code) =>
      permissionDeniedCodes.contains(code)
      ? PickStatus.permissionDenied
      : PickStatus.readFailed;

  static PickedImage _failed(PickStatus status) =>
      PickedImage.failed(status, InputKind.camera);

  /// image_picker가 앱 캐시에 남긴 촬영 파일을 지운다. 복사본을 만든 뒤에는 필요 없고,
  /// 남겨 두면 원본 사진이 앱 안에 쌓인다 (원본 미보관 원칙).
  ///
  /// 안전장치: 앱 전용 데이터 폴더 안의 파일일 때만 지운다 (임시 폴더의 상위 폴더 아래).
  /// Android에서 임시 폴더는 `/data/user/0/<앱>/code_cache`, image_picker 파일은 `/data/user/0/<앱>/cache/...`라
  /// 둘 다 같은 앱 폴더 아래다. 사용자 갤러리(`/storage/...`)의 파일은 이 조건을 통과하지 못한다.
  /// Android 36 에뮬레이터에서 촬영 파일이 `cache/` 아래에 생기고 이 함수로 지워지는 것을 확인했다 (11/12).
  Future<void> _deleteCameraFile(String path) async {
    if (_files.isAppCopy(path)) return;
    if (!_files.isInsideAppData(path)) return;
    try {
      await File(path).delete();
    } on FileSystemException {
      // 이미 없으면 무시
    }
  }
}
