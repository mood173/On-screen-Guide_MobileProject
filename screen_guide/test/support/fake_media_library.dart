// 시험용 사진 보관함. MediaGalleryInput 시험과 포트 공용 시험이 함께 쓴다.

import 'dart:typed_data';

import 'package:screen_guide/features/capture/data/media_gallery_input.dart';

/// 시험용 사진 보관함
class FakeLibrary implements MediaLibrary {
  FakeLibrary({
    this.access = true,
    List<MediaItem>? items,
    Map<String, MediaOriginal>? originals,
  }) : items = items ?? [],
       originals = originals ?? {};

  bool access;
  final List<MediaItem> items;
  final Map<String, MediaOriginal> originals;
  Object? throwOnAll;
  int originalCalls = 0;

  @override
  Future<bool> requestImageAccess() async {
    if (throwOnAll != null) throw throwOnAll!;
    return access;
  }

  @override
  Future<List<MediaItem>> latest(int limit) async {
    if (throwOnAll != null) throw throwOnAll!;
    return access ? items.take(limit).toList() : const [];
  }

  @override
  Future<MediaOriginal?> original(String id) async {
    originalCalls++;
    if (throwOnAll != null) throw throwOnAll!;
    return originals[id];
  }
}

MediaItem item(String id, {String? path, int minute = 0}) => MediaItem(
  id: id,
  relativePath: path,
  createdAt: DateTime(2026, 11, 13, 12, minute),
  thumbnail: Uint8List.fromList([1]),
);
