import 'dart:typed_data';

// 사진 가져오기 포트와 자료형. (협업규격_최종 3.1·3.2, 기능별_검토_결론 1-2)
// 구현: 최정혁(데이터·입출력) / 사용: 지형주(화면·흐름).
// 쓰는 쪽 기준으로 셋으로 나눈다: 갤러리 장면은 GalleryInput만, 카메라 장면은 CameraInput만,
// 흐름(세션 종료·앱 시작)과 권한 안내 화면은 InputCleanup만 본다.

/// 가져오기 결과. 성공 / 사용자 취소 / 권한 거부 / 파일 읽기 실패를 구분한다.
enum PickStatus { ok, cancelled, permissionDenied, readFailed }

/// 입력 방식. 실시간 안내가 붙으면 live를 더한다.
enum InputKind { gallery, camera }

/// 갤러리 목록 한 칸의 종류. 저장 폴더 이름이 Screenshots인지로 판단한다 (관례라 기기에 따라 틀릴 수 있다).
enum GalleryKind { photo, screenshot }

/// 갤러리 목록 한 칸. 화면이 그릴 때만 쓴다.
class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.thumbnail,
    required this.kind,
    required this.takenAt,
  });

  /// [GalleryInput.use]에 다시 넘기는 값
  final String id;

  /// 작은 미리보기만 (원본 아님)
  final Uint8List thumbnail;
  final GalleryKind kind;
  final DateTime takenAt;
}

/// 가져온 사진 한 장.
class PickedImage {
  const PickedImage({required this.status, this.path, required this.input});

  const PickedImage.failed(this.status, this.input) : path = null;

  final PickStatus status;

  /// 앱 임시 폴더에 만든 복사본의 파일 경로 (ok일 때만). 분석 요청 imagePath로 그대로 넘긴다.
  final String? path;
  final InputKind input;

  bool get ok => status == PickStatus.ok && path != null;
}

/// 갤러리 장면이 쓰는 포트. 정지 이미지 1장만 (제약 C01). 위치 등 메타데이터는 요청하지 않는다.
abstract interface class GalleryInput {
  /// 사진 접근 권한 확인·요청. ok 또는 permissionDenied.
  Future<PickStatus> requestAccess();

  /// 최근 사진·스크린샷 (최근 것부터, 최대 [limit]장)
  Future<List<GalleryItem>> recent({int limit = 9});

  /// 고른 한 장을 앱 복사본으로 준비한다.
  Future<PickedImage> use(String id);
}

/// 카메라 장면이 쓰는 포트. 기기 기본 카메라 앱으로 한 장 받는다.
abstract interface class CameraInput {
  Future<PickedImage> takePhoto();
}

/// 흐름(세션 종료·앱 시작)과 권한 안내 화면이 쓰는 포트.
abstract interface class InputCleanup {
  /// 앱이 만든 복사본만 지운다. 사용자 원본은 지우지 않는다.
  Future<void> release(PickedImage image);

  /// 앱 시작 때, 강제 종료 등으로 남은 복사본을 지운다.
  Future<void> clearLeftovers();

  /// 기기의 앱 권한 설정 화면을 연다.
  Future<void> openAppSettings();
}
