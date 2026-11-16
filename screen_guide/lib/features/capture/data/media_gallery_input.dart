import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import 'package:screen_guide/features/capture/data/app_copy_files.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';

/// 기기 사진 보관함의 사진 한 장 (목록용). 원본 경로는 담지 않는다.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.relativePath,
    required this.createdAt,
    required this.thumbnail,
  });

  final String id;

  /// 저장 폴더 (Android: `MediaStore.RELATIVE_PATH`, 예 `Pictures/Screenshots/`)
  final String? relativePath;
  final DateTime createdAt;
  final Uint8List thumbnail;
}

/// 사진 보관함 원본 한 장: 파일 이름과 내용.
class MediaOriginal {
  const MediaOriginal({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

/// 사진 보관함 접근. 포트가 아니라 [MediaGalleryInput] 안쪽 도구다 (시험에서 바꿔 끼우려고 분리).
abstract interface class MediaLibrary {
  /// 사진 접근 권한 확인·요청. 일부 사진만 허용한 상태도 true.
  Future<bool> requestImageAccess();

  /// 최근 사진 [limit]장 (최근 것부터). 권한이 없으면 빈 목록.
  Future<List<MediaItem>> latest(int limit);

  /// [id] 사진의 원본 내용. 없으면 null.
  Future<MediaOriginal?> original(String id);
}

/// `photo_manager`로 기기 사진 보관함을 읽는다.
/// 위치 메타데이터 권한(ACCESS_MEDIA_LOCATION)은 요청하지 않는다 (`mediaLocation: false`, 개념 정리 F01).
class PhotoManagerLibrary implements MediaLibrary {
  const PhotoManagerLibrary();

  static const _option = PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.image,
      mediaLocation: false,
    ),
  );

  static const thumbnailSize = ThumbnailSize.square(240);

  @override
  Future<bool> requestImageAccess() async =>
      (await PhotoManager.requestPermissionExtend(requestOption: _option))
          .hasAccess;

  @override
  Future<List<MediaItem>> latest(int limit) async {
    final state = await PhotoManager.getPermissionState(requestOption: _option);
    if (!state.hasAccess || limit <= 0) return const [];
    final assets = await PhotoManager.getAssetListRange(
      start: 0,
      end: limit,
      type: RequestType.image,
    );
    return [
      for (final a in assets)
        MediaItem(
          id: a.id,
          relativePath: a.relativePath,
          createdAt: a.createDateTime,
          thumbnail:
              await a.thumbnailDataWithSize(thumbnailSize, quality: 80) ??
              Uint8List(0),
        ),
    ];
  }

  @override
  Future<MediaOriginal?> original(String id) async {
    final asset = await AssetEntity.fromId(id);
    if (asset == null) return null;
    final bytes = await asset.originBytes;
    if (bytes == null) return null;
    return MediaOriginal(name: asset.title ?? 'image', bytes: bytes);
  }
}

/// [GalleryInput]의 진짜 구현. ── 최정혁 (협업규격_최종 4.3 #3)
///
/// 최근 사진·스크린샷 9장을 목록으로 주고(기능별_검토_결론 1-1 ⑥, 앨범 선택·더 불러오기 없음 X3·X4),
/// 고른 한 장을 앱 복사본(`sg_` 폴더)으로 만들어 그 경로를 돌려준다. 사용자 원본은 읽기만 한다.
/// 예외를 밖으로 던지지 않는다.
class MediaGalleryInput implements GalleryInput {
  MediaGalleryInput({AppCopyFiles? files, MediaLibrary? library})
    : _files = files ?? AppCopyFiles(),
      _library = library ?? const PhotoManagerLibrary();

  final AppCopyFiles _files;
  final MediaLibrary _library;

  /// 스크린샷 폴더 판단: 저장 폴더 경로에 `Screenshots` 폴더가 있으면 스크린샷 (관례, 기기마다 틀릴 수 있음 — 검토 결론 1-1 ④)
  static final _screenshotFolder = RegExp(
    r'(^|/)screenshots(/|$)',
    caseSensitive: false,
  );

  static GalleryKind kindOf(String? relativePath) =>
      relativePath != null && _screenshotFolder.hasMatch(relativePath)
      ? GalleryKind.screenshot
      : GalleryKind.photo;

  @override
  Future<PickStatus> requestAccess() async {
    try {
      return await _library.requestImageAccess()
          ? PickStatus.ok
          : PickStatus.permissionDenied;
    } catch (_) {
      return PickStatus.permissionDenied;
    }
  }

  @override
  Future<List<GalleryItem>> recent({int limit = 9}) async {
    if (limit <= 0) return const [];
    try {
      final items = await _library.latest(limit);
      return [
        for (final m in items.take(limit))
          GalleryItem(
            id: m.id,
            thumbnail: m.thumbnail,
            kind: kindOf(m.relativePath),
            takenAt: m.createdAt,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<PickedImage> use(String id) async {
    try {
      final original = await _library.original(id);
      if (original == null || original.bytes.isEmpty) return _failed();
      final path = await _files.saveBytes(original.name, original.bytes);
      return PickedImage(
        status: PickStatus.ok,
        path: path,
        input: InputKind.gallery,
      );
    } catch (_) {
      return _failed();
    }
  }

  static PickedImage _failed() =>
      const PickedImage.failed(PickStatus.readFailed, InputKind.gallery);
}
