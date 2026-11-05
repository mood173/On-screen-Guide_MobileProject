import '../contract/analysis.dart';
import '../core/error_code.dart';
import '../domain/screen_analyzer.dart';

/// 가짜 분석기. 계약 v1 문서의 예시 응답(시험 앱 샘플 1: 설정 화면)을 돌려준다.
///
/// - 요청의 requestId를 그대로 돌려준다.
/// - 요청에 target이 없으면 응답 target도 null (기능 선택 전 첫 분석).
/// - target.selector가 elements 라벨과 같으면 exact로 찾고, 아니면 null (NO_TARGET 시험용).
/// - [failWith]를 주면 그 오류로 실패한다 (E 화면 시험용).
class FakeAnalyzer implements ScreenAnalyzer {
  FakeAnalyzer({
    this.delay = const Duration(milliseconds: 600),
    this.failWith,
    this.unknownScreen = false,
  });

  /// 분석 중 화면을 볼 수 있게 일부러 기다리는 시간. 3초 초과 처리를 시험하려면 늘린다.
  final Duration delay;
  final ErrorCode? failWith;

  /// true면 화면 미식별(screenId == null) 응답을 준다.
  final bool unknownScreen;

  static const imageSize = (w: 1080, h: 2340);

  static const sampleElements = [
    UiElement(label: '설정', box: Box(80, 380, 190, 440)),
    UiElement(label: '설정 검색', box: Box(110, 520, 250, 560)),
    UiElement(label: '네트워크 및 인터넷', box: Box(196, 670, 520, 712)),
    UiElement(label: '연결된 기기', box: Box(196, 850, 392, 892)),
    UiElement(label: '앱', box: Box(196, 1030, 228, 1072)),
    UiElement(label: '알림 설정', box: Box(174, 1029, 341, 1070)),
    UiElement(label: '배터리', box: Box(196, 1390, 306, 1432)),
    UiElement(label: '010-1234-5678', box: Box(196, 1440, 420, 1478)),
    UiElement(label: '디스플레이', box: Box(196, 1930, 398, 1972)),
  ];

  @override
  Future<AnalysisResult> analyze(AnalyzeRequest request) async {
    await Future<void>.delayed(delay);
    if (failWith != null) return AnalysisResult.error(request.requestId, failWith!);

    TargetMatch? target;
    final selector = request.target?.selector;
    if (selector != null) {
      for (final e in sampleElements) {
        if (e.label == selector) {
          target = TargetMatch(label: e.label, box: e.box, match: MatchKind.exact);
          break;
        }
      }
    }

    return AnalysisResult(
      requestId: request.requestId,
      ok: true,
      imageWidth: imageSize.w,
      imageHeight: imageSize.h,
      screenId: unknownScreen ? null : 'settings',
      elements: sampleElements,
      target: target,
      pii: const [
        PiiCandidate(type: '휴대전화', masked: '010-****-**78', elementIndex: 7),
      ],
      piiEngine: const PiiEngine(regex: EngineStatus.ok, mlkit: EngineStatus.ok),
      ocrMs: delay.inMilliseconds,
      totalMs: delay.inMilliseconds,
    );
  }
}
