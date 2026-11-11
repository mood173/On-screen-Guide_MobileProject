/// 사진 가져오기 결과. (기능·개념 정리 F01: 성공 / 사용자 취소 / 권한 거부 / 파일 읽기 실패를 구분)
enum PickStatus { ok, cancelled, permissionDenied, readFailed }

class PickedImage {
  const PickedImage({
    required this.status,
    this.path,
    this.input = 'gallery',
    this.appOwned = false,
  });

  const PickedImage.failed(this.status)
    : path = null,
      input = 'gallery',
      appOwned = false;

  final PickStatus status;

  /// Kotlin이 열 수 있는 실제 파일 경로 (분석 요청 imagePath로 그대로 넘김)
  final String? path;

  /// gallery / camera
  final String input;

  /// 앱이 만든 복사본이면 true → 분석이 끝나면 지워도 된다. 사용자 원본은 false (지우면 안 됨).
  final bool appOwned;

  bool get ok => status == PickStatus.ok && path != null;
}

/// 포트: 사진 가져오기. ── 제공: 팀원 3 (image_picker) / 사용: 팀원 2 (G·C 화면)
///
/// - 정지 이미지 1장만 (C01). 갤러리는 위치 등 메타데이터를 요청하지 않는다 (requestFullMetadata: false).
/// - 위치·연락처 등 필요 없는 권한은 요청하지 않는다 (TC-F01-09).
/// 구현: FakeImageInput(지금, 샘플 이미지) → image_picker 구현(2주차)
abstract interface class ImageInput {
  Future<PickedImage> pickFromGallery();
  Future<PickedImage> takePhoto();

  /// [PickedImage.appOwned]인 것만 지운다.
  Future<void> release(PickedImage image);
}
