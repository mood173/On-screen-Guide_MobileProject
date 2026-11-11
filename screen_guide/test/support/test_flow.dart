// 시험용 흐름 조립. 앱의 bootstrap.dart와 같은 역할을 시험 안에서 한다 (구현 객체는 여기서 만든다).

import 'dart:typed_data';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/analyze/data/fake_analyzer.dart';
import 'package:screen_guide/features/analyze/domain/screen_analyzer.dart';
import 'package:screen_guide/features/capture/data/fake_input.dart';
import 'package:screen_guide/features/capture/data/image_files.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/guidance_map/data/demo_guidance.dart';
import 'package:screen_guide/features/guidance_map/data/fake_map_updater.dart';
import 'package:screen_guide/features/guidance_map/domain/guidance.dart';
import 'package:screen_guide/features/history/data/in_memory_history_repository.dart';
import 'package:screen_guide/features/history/domain/history.dart';
import 'package:screen_guide/features/share/data/fake_sharer.dart';

Future<Uint8List> noThumbnail(String _) async => Uint8List(0);

GuideFlow testFlow({
  ScreenAnalyzer? analyzer,
  GuidanceRepository? guidance,
  HistoryRepository? history,
  ImageFiles files = const AssetPathImageFiles(),
  GalleryInput? gallery,
  InputCleanup? cleanup,
  Duration slowAfter = const Duration(seconds: 3),
  DateTime Function()? now,
}) => GuideFlow(
  analyzer: analyzer ?? FakeAnalyzer(delay: Duration.zero),
  guidance: guidance ?? const DemoGuidanceRepository(),
  history: history ?? InMemoryHistoryRepository(),
  galleryInput:
      gallery ?? FakeGalleryInput(files: files, loadThumbnail: noThumbnail),
  cameraInput: FakeCameraInput(files: files),
  inputCleanup: cleanup ?? FakeInputCleanup(files: files),
  sharer: FakeSharer(),
  mapUpdater: FakeMapUpdater(),
  slowAfter: slowAfter,
  now: now ?? () => DateTime(2026, 11, 20, 10),
);
