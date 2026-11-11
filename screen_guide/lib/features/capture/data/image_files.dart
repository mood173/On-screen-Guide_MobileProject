import 'dart:io';

import 'package:flutter/services.dart';

import 'package:screen_guide/features/capture/data/sample_images.dart';

/// 분석 요청의 imagePath는 Kotlin이 열 수 있는 실제 파일 경로여야 한다(계약 v1 결정 1).
/// 샘플은 Flutter 에셋이라 파일이 아니므로, 앱 캐시 폴더에 복사본을 만들어 그 경로를 쓴다.
///
/// 앱이 만든 복사본만 지운다. 사용자 원본은 지우지 않는다 (기능·개념 정리 12.1 ⑨).
abstract interface class ImageFiles {
  Future<String> prepare(SampleImage sample);
  Future<void> release(String path);
}

/// 실제 구현: Android에서 [Directory.systemTemp]는 앱 전용 임시 폴더(`code_cache`)다.
/// 다른 앱은 읽을 수 없고, 앱을 지우면 함께 지워진다. (에뮬레이터에서 생성·삭제 확인, 2026-11-06)
class CacheImageFiles implements ImageFiles {
  @override
  Future<String> prepare(SampleImage sample) async {
    final bytes = await rootBundle.load(sample.asset);
    final dir = await Directory.systemTemp.createTemp('sg_');
    final file = File('${dir.path}/${sample.asset.split('/').last}');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file.path;
  }

  @override
  Future<void> release(String path) async {
    try {
      final dir = File(path).parent;
      if (dir.path.contains('sg_')) await dir.delete(recursive: true);
    } on FileSystemException {
      // 이미 지워졌으면 무시
    }
  }
}

/// 시험용: 파일을 만들지 않고 에셋 경로를 그대로 쓴다 (가짜 분석기는 파일 이름으로 샘플을 찾음).
class AssetPathImageFiles implements ImageFiles {
  const AssetPathImageFiles();

  @override
  Future<String> prepare(SampleImage sample) async => sample.asset;

  @override
  Future<void> release(String path) async {}
}
