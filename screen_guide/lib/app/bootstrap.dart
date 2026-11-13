import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/analyze/data/fake_analyzer.dart';
import 'package:screen_guide/features/analyze/data/method_channel_analyzer.dart';
import 'package:screen_guide/features/analyze/domain/screen_analyzer.dart';
import 'package:screen_guide/features/capture/data/fake_input.dart';
import 'package:screen_guide/features/capture/data/file_input_cleanup.dart';
import 'package:screen_guide/features/capture/data/image_files.dart';
import 'package:screen_guide/features/capture/data/picker_camera_input.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/guidance_map/data/demo_guidance.dart';
import 'package:screen_guide/features/guidance_map/data/fake_map_updater.dart';
import 'package:screen_guide/features/guidance_map/domain/guidance.dart';
import 'package:screen_guide/features/guidance_map/domain/map_updater.dart';
import 'package:screen_guide/features/history/data/in_memory_history_repository.dart';
import 'package:screen_guide/features/history/domain/history.dart';
import 'package:screen_guide/features/share/data/fake_sharer.dart';
import 'package:screen_guide/features/share/domain/sharer.dart';

/// 실행 시 `--dart-define=FAKE_ANALYZER=false`를 주면 실제 Kotlin 분석기를 쓴다.
/// 기본값은 가짜 분석기: Kotlin 채널이 계약 v1 응답 형식으로 바뀌기 전까지 화면 작업은 가짜로 한다.
const bool useFakeAnalyzer = bool.fromEnvironment(
  'FAKE_ANALYZER',
  defaultValue: true,
);

/// 앱 전체의 연결 지점 묶음. (개발 계약 v1 결정 3: 외부 DI 패키지 없이 생성자 주입)
///
/// 구현 객체를 만드는 곳은 **이 파일뿐**이다 (협업규격_최종 2장). 진짜 구현을 만든 사람이
/// 그 포트의 공용 시험(test/ports/)을 통과시킨 뒤 [bootstrap]에서 **자기 줄만** 바꿔 끼운다.
///
/// | 포트 | 구현 담당 | 지금 | 진짜로 바꿀 때 |
/// |---|---|---|---|
/// | ScreenAnalyzer | 강민준 | FakeAnalyzer | MethodChannelAnalyzer (Kotlin 채널이 계약 v1 형식이 되면) |
/// | GuidanceRepository | 최정혁 | DemoGuidanceRepository | 실제 앱 기능 맵 |
/// | HistoryRepository | 최정혁 | InMemoryHistoryRepository | 로컬 DB 구현 |
/// | CameraInput | 최정혁 | **PickerCameraInput** (image_picker) | — (교체함, 11/12) |
/// | InputCleanup | 최정혁 | **FileInputCleanup** (앱 복사본·image_picker 잔여 정리, app_settings) | — (교체함, 11/13) |
/// | GalleryInput | 최정혁 | FakeGalleryInput (샘플 이미지) | 실제 갤러리 구현 |
/// | Sharer | 최정혁 | FakeSharer | share_plus 구현 |
/// | MapUpdater | 최정혁 | FakeMapUpdater | Firebase 구현 (선택) |
class AppDependencies {
  const AppDependencies({
    required this.analyzer,
    required this.guidance,
    required this.history,
    required this.galleryInput,
    required this.cameraInput,
    required this.inputCleanup,
    required this.sharer,
    required this.mapUpdater,
  });

  final ScreenAnalyzer analyzer;
  final GuidanceRepository guidance;
  final HistoryRepository history;
  final GalleryInput galleryInput;
  final CameraInput cameraInput;
  final InputCleanup inputCleanup;
  final Sharer sharer;
  final MapUpdater mapUpdater;

  GuideFlow createFlow() => GuideFlow(
    analyzer: analyzer,
    guidance: guidance,
    history: history,
    galleryInput: galleryInput,
    cameraInput: cameraInput,
    inputCleanup: inputCleanup,
    sharer: sharer,
    mapUpdater: mapUpdater,
  );
}

AppDependencies bootstrap({bool? fake}) {
  final useFake = fake ?? useFakeAnalyzer;
  final files = CacheImageFiles(); // 가짜 입력이 샘플을 앱 임시 폴더에 복사할 때 쓴다
  return AppDependencies(
    analyzer: useFake ? FakeAnalyzer() : MethodChannelAnalyzer(), // 강민준
    guidance: const DemoGuidanceRepository(), // 최정혁: 실제 앱 기능 맵으로 교체
    history: InMemoryHistoryRepository(), // 최정혁: 로컬 DB 구현으로 교체
    galleryInput: FakeGalleryInput(files: files), // 최정혁: 실제 갤러리 구현으로 교체
    cameraInput: PickerCameraInput(), // 최정혁: image_picker (기기 기본 카메라)
    inputCleanup: FileInputCleanup(), // 최정혁: 앱 복사본·image_picker 잔여 정리, 설정 열기
    sharer: FakeSharer(), // 최정혁: share_plus 구현으로 교체
    mapUpdater: FakeMapUpdater(), // 최정혁: Firebase 구현으로 교체 (선택)
  );
}
