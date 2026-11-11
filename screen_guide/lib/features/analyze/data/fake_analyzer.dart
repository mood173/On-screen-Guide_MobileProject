import 'package:screen_guide/features/analyze/domain/screen_analyzer.dart';
import 'package:screen_guide/features/analyze/data/sample_answers.dart';
import 'package:screen_guide/shared/contracts/analysis.dart';
import 'package:screen_guide/shared/contracts/error_code.dart';

/// 가짜 분석기. 요청 imagePath의 파일 이름으로 [SampleAnswer]를 찾아 그 샘플의 실제 OCR 결과를 돌려준다.
/// 모르는 경로면 설정 화면 샘플로 본다.
///
/// 진짜 Kotlin 분석기와 같은 규칙을 흉내 낸다 (설계 10장):
/// - 화면 식별: 요청에 함께 온 기능 맵 조각의 anchors 중 2개 이상이 보여야 그 화면. 아니면 screenId null.
/// - 대상 찾기: 정확 일치(공백 무시) → 없으면 길이가 같고 한 글자만 다른 후보가 1개일 때만 fuzzy. 그 외 null.
/// - [failWith]를 주면 그 오류로 실패한다 (E 화면 시험용).
class FakeAnalyzer implements ScreenAnalyzer {
  FakeAnalyzer({
    this.delay = const Duration(milliseconds: 1200),
    this.failWith,
  });

  /// 분석 중 화면을 볼 수 있게 일부러 기다리는 시간.
  final Duration delay;
  final ErrorCode? failWith;

  @override
  Future<AnalysisResult> analyze(AnalyzeRequest request) async {
    await Future<void>.delayed(delay);
    if (failWith != null) {
      return AnalysisResult.error(request.requestId, failWith!);
    }

    final sample =
        SampleAnswer.byPath(request.imagePath) ?? SampleAnswer.settings;
    final elements = sample.elements;

    return AnalysisResult(
      requestId: request.requestId,
      ok: true,
      imageWidth: sample.width,
      imageHeight: sample.height,
      screenId: _identify(elements, request.guidance),
      elements: elements,
      target: request.target == null
          ? null
          : _findTarget(elements, request.target!.selector),
      pii: sample.pii,
      piiEngine: const PiiEngine(
        regex: EngineStatus.ok,
        mlkit: EngineStatus.ok,
      ),
      ocrMs: delay.inMilliseconds,
      totalMs: delay.inMilliseconds,
    );
  }

  static String _norm(String s) => s.replaceAll(RegExp(r'[\s·:]'), '');

  static bool _hasAnchor(String label, String anchor) =>
      _norm(label) == _norm(anchor) ||
      label.split(RegExp(r'\s+')).any((w) => _norm(w) == _norm(anchor));

  static String? _identify(List<UiElement> elements, GuidanceFragment g) {
    for (final s in g.screens) {
      final seen = s.anchors
          .where((a) => elements.any((e) => _hasAnchor(e.label, a)))
          .length;
      if (seen >= 2) return s.screenId;
    }
    return null;
  }

  static TargetMatch? _findTarget(List<UiElement> elements, String selector) {
    final s = _norm(selector);
    for (final e in elements) {
      if (_norm(e.label) == s) {
        return TargetMatch(label: e.label, box: e.box, match: MatchKind.exact);
      }
    }
    if (s.length < 2) return null;
    final near = elements.where((e) {
      final l = _norm(e.label);
      if (l.length != s.length) return false;
      var diff = 0;
      for (var i = 0; i < l.length; i++) {
        if (l[i] != s[i]) diff++;
      }
      return diff == 1;
    }).toList();
    if (near.length != 1) return null;
    return TargetMatch(
      label: near.first.label,
      box: near.first.box,
      match: MatchKind.fuzzy,
    );
  }
}
