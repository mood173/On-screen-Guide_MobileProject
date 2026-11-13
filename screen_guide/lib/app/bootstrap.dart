import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/analyze/data/fake_analyzer.dart';
import 'package:screen_guide/features/analyze/data/method_channel_analyzer.dart';
import 'package:screen_guide/features/analyze/domain/screen_analyzer.dart';
import 'package:screen_guide/features/capture/data/fake_input.dart';
import 'package:screen_guide/features/capture/data/file_input_cleanup.dart';
import 'package:screen_guide/features/capture/data/image_files.dart';
import 'package:screen_guide/features/capture/data/media_gallery_input.dart';
import 'package:screen_guide/features/capture/data/picker_camera_input.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/guidance_map/data/asset_guidance_repository.dart';
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
/// | GuidanceRepository | 최정혁 | **AssetGuidanceRepository** (앱에 든 JSON 맵, 지금은 체험용과 같은 내용) | 실제 앱 맵 내용으로 JSON 교체 (11/27) |
/// | HistoryRepository | 최정혁 | InMemoryHistoryRepository | 로컬 DB 구현 |
/// | CameraInput | 최정혁 | **PickerCameraInput** (image_picker) | — (교체함, 11/12) |
/// | InputCleanup | 최정혁 | **FileInputCleanup** (앱 복사본·image_picker 잔여 정리, app_settings) | — (교체함, 11/13) |
/// | GalleryInput | 최정혁 | **MediaGalleryInput** (photo_manager) — `FAKE_ANALYZER=false`일 때만. 가짜 분석기 모드는 FakeGalleryInput(샘플) | 실제 분석기가 기본이 되면 항상 진짜 |
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
    guidance: AssetGuidanceRepository(), // 최정혁: assets/feature_maps/ JSON 맵
    history: InMemoryHistoryRepository(), // 최정혁: 로컬 DB 구현으로 교체
    // 최정혁: 실제 분석기면 기기 사진 보관함, 가짜 분석기면 체험용 샘플 갤러리
    // (가짜 분석기는 샘플 파일 이름으로 정답을 찾으므로 기기 사진으로는 체험 흐름이 돌지 않는다)
    galleryInput: useFake
        ? FakeGalleryInput(files: files)
        : MediaGalleryInput(),
    cameraInput: PickerCameraInput(), // 최정혁: image_picker (기기 기본 카메라)
    inputCleanup: FileInputCleanup(), // 최정혁: 앱 복사본·image_picker 잔여 정리, 설정 열기
    sharer: FakeSharer(), // 최정혁: share_plus 구현으로 교체
    mapUpdater: FakeMapUpdater(), // 최정혁: Firebase 구현으로 교체 (선택)
  );
}
