// 채널 screen_guide/analyze · 메서드 analyze 의 요청·응답 형식. (개발 계약 v1 · 결정 1)
//
// 필드 이름과 의미는 계약 문서의 JSON과 1:1로 맞춘다. 바꿀 때는 계약 문서를 먼저 고친다.
// Kotlin 쪽도 같은 이름을 쓴다. 넘기지 않는 것: OCR 원문 전체, 개인정보 후보 원문.

import 'package:screen_guide/shared/contracts/error_code.dart';

/// 원본 이미지 픽셀 좌표 [left, top, right, bottom].
/// 화면에 그릴 때는 CoordinateMapper로 변환한다.
class Box {
  const Box(this.left, this.top, this.right, this.bottom);

  final int left, top, right, bottom;

  int get width => right - left;
  int get height => bottom - top;

  factory Box.fromJson(List<dynamic> j) =>
      Box(_int(j[0]), _int(j[1]), _int(j[2]), _int(j[3]));

  List<int> toJson() => [left, top, right, bottom];

  @override
  bool operator ==(Object other) =>
      other is Box &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'Box($left, $top, $right, $bottom)';
}

// ───────────────────────────── 요청 (Flutter → Kotlin) ─────────────────────────────

/// 화면 식별 기준 하나. anchors 중 2개 이상이 보이면 그 화면.
class ScreenAnchors {
  const ScreenAnchors({required this.screenId, required this.anchors});

  final String screenId;
  final List<String> anchors;

  factory ScreenAnchors.fromJson(Map<String, dynamic> j) => ScreenAnchors(
    screenId: j['screenId'] as String,
    anchors: (j['anchors'] as List).cast<String>(),
  );

  Map<String, dynamic> toJson() => {'screenId': screenId, 'anchors': anchors};
}

/// 요청에 함께 넘기는 기능 맵 조각 (해당 앱의 화면 앵커).
class GuidanceFragment {
  const GuidanceFragment({required this.packageName, required this.screens});

  final String packageName;
  final List<ScreenAnchors> screens;

  factory GuidanceFragment.fromJson(Map<String, dynamic> j) => GuidanceFragment(
    packageName: j['packageName'] as String,
    screens: (j['screens'] as List)
        .map((e) => ScreenAnchors.fromJson(_map(e)))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'screens': screens.map((s) => s.toJson()).toList(),
  };
}

/// 이번 단계에서 찾을 대상. 기능을 고르기 전 첫 분석에서는 보내지 않는다.
class TargetRequest {
  const TargetRequest({
    required this.actionId,
    required this.stepIndex,
    required this.selector,
  });

  /// 앱 기능 ID (영역.동작, 예: settings.notification)
  final String actionId;
  final int stepIndex;
  final String selector;

  factory TargetRequest.fromJson(Map<String, dynamic> j) => TargetRequest(
    actionId: j['actionId'] as String,
    stepIndex: _int(j['stepIndex']),
    selector: j['selector'] as String,
  );

  Map<String, dynamic> toJson() => {
    'actionId': actionId,
    'stepIndex': stepIndex,
    'selector': selector,
  };
}

class AnalyzeRequest {
  const AnalyzeRequest({
    required this.requestId,
    required this.imagePath,
    required this.guidance,
    this.target,
  });

  final String requestId;
  final String imagePath;
  final GuidanceFragment guidance;
  final TargetRequest? target;

  factory AnalyzeRequest.fromJson(Map<String, dynamic> j) => AnalyzeRequest(
    requestId: j['requestId'] as String,
    imagePath: j['imagePath'] as String,
    guidance: GuidanceFragment.fromJson(_map(j['guidance'])),
    target: j['target'] == null
        ? null
        : TargetRequest.fromJson(_map(j['target'])),
  );

  /// target이 없으면 키 자체를 빼고 보낸다.
  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'imagePath': imagePath,
    'guidance': guidance.toJson(),
    if (target != null) 'target': target!.toJson(),
  };
}

// ───────────────────────────── 응답 (Kotlin → Flutter) ─────────────────────────────

enum MatchKind {
  /// 정확 일치
  exact,

  /// 한 글자 차이 (OCR 오인식 허용)
  fuzzy,
}

/// 인식한 UI 요소 (라벨 + 위치).
class UiElement {
  const UiElement({required this.label, required this.box});

  final String label;
  final Box box;

  factory UiElement.fromJson(Map<String, dynamic> j) => UiElement(
    label: j['label'] as String,
    box: Box.fromJson(j['box'] as List),
  );

  Map<String, dynamic> toJson() => {'label': label, 'box': box.toJson()};
}

class TargetMatch {
  const TargetMatch({
    required this.label,
    required this.box,
    required this.match,
  });

  final String label;
  final Box box;
  final MatchKind match;

  factory TargetMatch.fromJson(Map<String, dynamic> j) => TargetMatch(
    label: j['label'] as String,
    box: Box.fromJson(j['box'] as List),
    match: MatchKind.values.byName(j['match'] as String),
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'box': box.toJson(),
    'match': match.name,
  };
}

/// 개인정보 후보. 원문은 오지 않고 가린 값(앞 3자·뒤 2자)만 온다.
/// 개인정보 후보 유형 9개 (협업규격_최종 3.3). pii[].type은 이 값 중 하나이고 엔진 이름을 붙이지 않는다.
const piiTypes = [
  '주민·외국인등록번호',
  '휴대전화',
  '유선전화',
  '계좌번호 추정',
  '전화',
  '이메일',
  '주소',
  '카드',
  'URL',
];

class PiiCandidate {
  const PiiCandidate({
    required this.type,
    required this.masked,
    required this.elementIndex,
  });

  /// 유형 이름: [piiTypes] 9개 중 하나
  final String type;
  final String masked;

  /// elements 목록에서 이 후보가 들어 있는 요소의 위치. 강조 상자를 그릴 때 쓴다.
  final int elementIndex;

  factory PiiCandidate.fromJson(Map<String, dynamic> j) => PiiCandidate(
    type: j['type'] as String,
    masked: j['masked'] as String,
    elementIndex: _int(j['elementIndex']),
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'masked': masked,
    'elementIndex': elementIndex,
  };
}

enum EngineStatus { ok, failed }

class PiiEngine {
  const PiiEngine({required this.regex, required this.mlkit});

  final EngineStatus regex;

  /// failed(모델 미다운로드 포함)여도 정규식 결과로 진행한다.
  final EngineStatus mlkit;

  factory PiiEngine.fromJson(Map<String, dynamic> j) => PiiEngine(
    regex: EngineStatus.values.byName(j['regex'] as String),
    mlkit: EngineStatus.values.byName(j['mlkit'] as String),
  );

  Map<String, dynamic> toJson() => {'regex': regex.name, 'mlkit': mlkit.name};
}

class AnalysisResult {
  const AnalysisResult({
    required this.requestId,
    required this.ok,
    this.errorCode,
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.screenId,
    this.elements = const [],
    this.target,
    this.pii = const [],
    this.piiEngine,
    this.ocrMs = 0,
    this.totalMs = 0,
  });

  /// Kotlin 쪽 실패를 Flutter에서 같은 모양으로 다루기 위한 생성자.
  const AnalysisResult.error(this.requestId, ErrorCode code)
    : ok = false,
      errorCode = code,
      imageWidth = 0,
      imageHeight = 0,
      screenId = null,
      elements = const [],
      target = null,
      pii = const [],
      piiEngine = null,
      ocrMs = 0,
      totalMs = 0;

  final String requestId;

  /// status == "ok"
  final bool ok;
  final ErrorCode? errorCode;
  final int imageWidth, imageHeight;

  /// null이면 화면 미식별 → Flutter가 UNKNOWN_SCREEN으로 E 화면
  final String? screenId;
  final List<UiElement> elements;

  /// null이면 요청에 target이 없었거나 후보가 0개·2개 이상 → 안내 중이면 NO_TARGET
  final TargetMatch? target;
  final List<PiiCandidate> pii;
  final PiiEngine? piiEngine;
  final int ocrMs, totalMs;

  factory AnalysisResult.fromJson(Map<String, dynamic> j) {
    final size = j['imageSize'] == null ? null : _map(j['imageSize']);
    final timing = j['timingMs'] == null ? null : _map(j['timingMs']);
    return AnalysisResult(
      requestId: j['requestId'] as String,
      ok: j['status'] == 'ok',
      errorCode: j['errorCode'] == null
          ? null
          : ErrorCode.fromWire(j['errorCode'] as String),
      imageWidth: size == null ? 0 : _int(size['w']),
      imageHeight: size == null ? 0 : _int(size['h']),
      screenId: j['screenId'] as String?,
      elements: ((j['elements'] as List?) ?? const [])
          .map((e) => UiElement.fromJson(_map(e)))
          .toList(),
      target: j['target'] == null
          ? null
          : TargetMatch.fromJson(_map(j['target'])),
      pii: ((j['pii'] as List?) ?? const [])
          .map((e) => PiiCandidate.fromJson(_map(e)))
          .toList(),
      piiEngine: j['piiEngine'] == null
          ? null
          : PiiEngine.fromJson(_map(j['piiEngine'])),
      ocrMs: timing == null ? 0 : _int(timing['ocr']),
      totalMs: timing == null ? 0 : _int(timing['total']),
    );
  }

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'status': ok ? 'ok' : 'error',
    'errorCode': errorCode?.wire,
    'imageSize': {'w': imageWidth, 'h': imageHeight},
    'screenId': screenId,
    'elements': elements.map((e) => e.toJson()).toList(),
    'target': target?.toJson(),
    'pii': pii.map((p) => p.toJson()).toList(),
    'piiEngine': piiEngine?.toJson(),
    'timingMs': {'ocr': ocrMs, 'total': totalMs},
  };
}

// MethodChannel은 Map<Object?, Object?>로 넘어오므로 키를 String으로 맞춘다.
Map<String, dynamic> _map(Object? o) => Map<String, dynamic>.from(o as Map);

// 채널을 거치면 int가 long·double로 올 수 있어 num으로 받는다.
int _int(Object? o) => (o as num).toInt();
