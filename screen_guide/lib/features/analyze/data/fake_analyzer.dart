import 'package:flutter/foundation.dart';

import 'package:screen_guide/features/analyze/domain/screen_analyzer.dart';
import 'package:screen_guide/features/analyze/data/sample_answers.dart';
import 'package:screen_guide/shared/contracts/analysis.dart';
import 'package:screen_guide/shared/contracts/error_code.dart';

/// 가짜 분석기. 요청 imagePath의 파일 이름으로 [SampleAnswer]를 찾아 그 샘플의 실제 OCR 결과를 돌려준다.
/// 모르는 경로면 설정 화면 샘플로 본다.
///
/// 진짜 Kotlin 분석기와 같은 규칙의 **복사본**이다. 기준은 Kotlin이다 (협업규격_최종 3.3, 기능별_검토_결론 2-2).
/// - 화면 식별 (A·B): 앵커 2개 이상이 **서로 다른 요소**에서 맞아야 한다. 여러 화면이 맞으면 맞은 수가
///   가장 많은 화면, 같은 수면 식별하지 않는다(screenId null). 추정으로 고르지 않는다.
/// - 대상 찾기 (C): 정확히 같은 요소가 **하나일 때만**. 없으면 길이가 같고 한 글자만 다른 요소가 하나일 때만
///   (선택자 2자 이상). 그 밖은 null.
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
      screenId: identify(elements, request.guidance),
      elements: elements,
      target: request.target == null
          ? null
          : findTarget(elements, request.target!.selector),
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

  /// 이 화면의 앵커 중 몇 개가 서로 다른 요소에서 보이는가.
  /// 한 요소는 앵커 하나에만 쓴다 (앵커-요소 최대 짝짓기, 작은 입력이라 단순 탐색).
  static int _matched(List<UiElement> elements, List<String> anchors) {
    final owner = <int, int>{}; // 요소 번호 → 앵커 번호
    bool assign(int a, Set<int> seen) {
      for (var i = 0; i < elements.length; i++) {
        if (seen.contains(i) || !_hasAnchor(elements[i].label, anchors[a])) {
          continue;
        }
        seen.add(i);
        final prev = owner[i];
        if (prev == null || assign(prev, seen)) {
          owner[i] = a;
          return true;
        }
      }
      return false;
    }

    var n = 0;
    for (var a = 0; a < anchors.length; a++) {
      if (assign(a, <int>{})) n++;
    }
    return n;
  }

  @visibleForTesting
  static String? identify(List<UiElement> elements, GuidanceFragment g) {
    String? best;
    var bestN = 1; // 2개 이상이어야 후보
    var tie = false;
    for (final s in g.screens) {
      final n = _matched(elements, s.anchors);
      if (n > bestN) {
        best = s.screenId;
        bestN = n;
        tie = false;
      } else if (n == bestN && best != null) {
        tie = true;
      }
    }
    return tie ? null : best;
  }

  @visibleForTesting
  static TargetMatch? findTarget(List<UiElement> elements, String selector) {
    final s = _norm(selector);
    final exact = elements.where((e) => _norm(e.label) == s).toList();
    if (exact.length == 1) {
      final e = exact.single;
      return TargetMatch(label: e.label, box: e.box, match: MatchKind.exact);
    }
    if (exact.length > 1) return null; // 같은 글자가 둘 이상이면 고르지 않는다
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
