import 'data/fake_analyzer.dart';
import 'data/method_channel_analyzer.dart';
import 'domain/screen_analyzer.dart';

/// 실행 시 `--dart-define=FAKE_ANALYZER=false`를 주면 실제 Kotlin 분석기를 쓴다.
/// 기본값은 가짜 분석기: Kotlin 채널이 계약 v1 응답 형식으로 바뀌기 전까지 화면 작업은 가짜로 한다.
const bool useFakeAnalyzer = bool.fromEnvironment('FAKE_ANALYZER', defaultValue: true);

/// 앱 전체에서 쓰는 구현체 묶음. (개발 계약 v1 · 결정 3: 외부 DI 패키지 없이 생성자 주입)
///
/// 새 포트(GuidanceRepository, HistoryRepository 등)가 생기면 여기에 필드를 추가하고
/// [bootstrap]에서 실제/가짜 구현을 골라 넣는다. 구현체를 만드는 곳은 이 파일 하나뿐이다.
class AppDependencies {
  const AppDependencies({required this.analyzer});

  final ScreenAnalyzer analyzer;
}

AppDependencies bootstrap({bool? fake}) {
  final useFake = fake ?? useFakeAnalyzer;
  return AppDependencies(
    analyzer: useFake ? FakeAnalyzer() : MethodChannelAnalyzer(),
  );
}
