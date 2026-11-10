import 'data/demo_guidance.dart';
import 'data/fake_analyzer.dart';
import 'data/fakes.dart';
import 'data/image_files.dart';
import 'data/method_channel_analyzer.dart';
import 'domain/guidance.dart';
import 'domain/history.dart';
import 'domain/image_input.dart';
import 'domain/screen_analyzer.dart';
import 'domain/share_and_update.dart';
import 'runtime/guide_flow.dart';

/// 실행 시 `--dart-define=FAKE_ANALYZER=false`를 주면 실제 Kotlin 분석기를 쓴다.
/// 기본값은 가짜 분석기: Kotlin 채널이 계약 v1 응답 형식으로 바뀌기 전까지 화면 작업은 가짜로 한다.
const bool useFakeAnalyzer = bool.fromEnvironment(
  'FAKE_ANALYZER',
  defaultValue: true,
);

/// 앱 전체의 연결 지점 묶음. (개발 계약 v1 · 결정 3: 외부 DI 패키지 없이 생성자 주입)
///
/// 각 팀원이 진짜 구현을 만들면 **이 파일의 [bootstrap]에서 한 줄만 바꿔** 끼운다.
/// 바꾸기 전에 그 포트의 공용 시험(test/ports/)을 통과해야 한다.
///
/// | 포트 | 제공 | 지금 | 진짜로 바꿀 때 |
/// |---|---|---|---|
/// | ScreenAnalyzer | 팀원 1 | FakeAnalyzer | MethodChannelAnalyzer (Kotlin 채널이 계약 v1 형식이 되면) |
/// | GuidanceRepository | 팀원 3 | DemoGuidanceRepository | 로컬 DB 구현 |
/// | HistoryRepository | 팀원 3 | InMemoryHistoryRepository | 로컬 DB 구현 |
/// | ImageInput | 팀원 3 | FakeImageInput | image_picker 구현 |
/// | Sharer | 팀원 3 | FakeSharer | share_plus 구현 |
/// | MapUpdater | 팀원 3 | FakeMapUpdater | Firebase 구현 |
class AppDependencies {
  const AppDependencies({
    required this.analyzer,
    required this.imageFiles,
    required this.guidance,
    required this.history,
    required this.imageInput,
    required this.sharer,
    required this.mapUpdater,
  });

  final ScreenAnalyzer analyzer;
  final ImageFiles imageFiles;
  final GuidanceRepository guidance;
  final HistoryRepository history;
  final ImageInput imageInput;
  final Sharer sharer;
  final MapUpdater mapUpdater;

  GuideFlow createFlow() => GuideFlow(
    analyzer: analyzer,
    files: imageFiles,
    guidance: guidance,
    history: history,
    imageInput: imageInput,
    sharer: sharer,
    mapUpdater: mapUpdater,
  );
}

AppDependencies bootstrap({bool? fake}) {
  final useFake = fake ?? useFakeAnalyzer;
  final files = CacheImageFiles();
  return AppDependencies(
    analyzer: useFake ? FakeAnalyzer() : MethodChannelAnalyzer(), // 팀원 1
    imageFiles: files,
    guidance: const DemoGuidanceRepository(), // 팀원 3: 로컬 DB 구현으로 교체
    history: InMemoryHistoryRepository(), // 팀원 3: 로컬 DB 구현으로 교체
    imageInput: FakeImageInput(files: files), // 팀원 3: image_picker 구현으로 교체
    sharer: FakeSharer(), // 팀원 3: share_plus 구현으로 교체
    mapUpdater: FakeMapUpdater(), // 팀원 3: Firebase 구현으로 교체
  );
}
