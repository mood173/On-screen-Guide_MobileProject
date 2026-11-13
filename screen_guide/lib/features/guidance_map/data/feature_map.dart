import 'dart:convert';

import 'package:screen_guide/features/guidance_map/domain/guidance.dart';
import 'package:screen_guide/shared/contracts/analysis.dart';

/// 기능 맵 파일의 저장 모양 (schema v1). ── 최정혁
///
/// 데이터 구현 **안쪽**에서만 쓴다 (협업규격_최종 7장). 화면·흐름에는 [GuideAction]·[GuideStep]·
/// [GuidanceFragment]만 나간다. 형식은 `assets/feature_maps/schema_v1.json`에 적어 두었다.
class FeatureMap {
  const FeatureMap({
    required this.schemaVersion,
    required this.revision,
    required this.apps,
  });

  final int schemaVersion;
  final String revision;
  final List<AppGuide> apps;

  static const supportedSchemaVersion = 1;

  /// JSON 글을 읽고 규칙을 확인한다. 하나라도 어기면 [FeatureMapException] — 맵 전체를 거부한다.
  static FeatureMap parse(String source) {
    final Object? j;
    try {
      j = jsonDecode(source);
    } on FormatException catch (e) {
      throw FeatureMapException('JSON이 아니다: ${e.message}');
    }
    final map = FeatureMap._fromJson(_obj(j, '맵'));
    map._checkRules();
    return map;
  }

  factory FeatureMap._fromJson(Map<String, Object?> j) {
    final version = _int(j, 'schemaVersion');
    if (version != supportedSchemaVersion) {
      throw FeatureMapException(
        'schemaVersion $version은 읽을 수 없다 (지원: $supportedSchemaVersion)',
      );
    }
    return FeatureMap(
      schemaVersion: version,
      revision: _str(j, 'revision', nonEmpty: true),
      apps: _list(
        j,
        'apps',
        minItems: 1,
      ).map((e) => AppGuide._fromJson(_obj(e, 'apps[]'))).toList(),
    );
  }

  Iterable<ScreenDef> get screens => apps.expand((a) => a.screens);
  Iterable<ActionDef> get actions => apps.expand((a) => a.actions);

  /// 분석 요청에 넣을 맵 조각. 지원하는 모든 앱의 화면을 담는다 (스크린샷만으로는 앱을 알 수 없다).
  /// packageName: 앱이 하나면 그 이름, 여럿이면 빈 문자열 (협업규격_최종 3.3 [제안]).
  GuidanceFragment toFragment() => GuidanceFragment(
    packageName: apps.length == 1 ? apps.single.packageName : '',
    screens: [
      for (final s in screens)
        ScreenAnchors(screenId: s.screenId, anchors: s.anchors),
    ],
  );

  /// 협업규격_최종 3.2 "기능 맵 규칙" 중 한 항목 안에서 확인할 수 없는 것들.
  void _checkRules() {
    final screenIds = <String>{};
    for (final s in screens) {
      if (!screenIds.add(s.screenId)) {
        throw FeatureMapException('화면 ID가 겹친다: ${s.screenId}');
      }
    }
    final actionIds = <String>{};
    for (final a in actions) {
      if (!actionIds.add(a.actionId)) {
        throw FeatureMapException('기능 ID가 겹친다: ${a.actionId}');
      }
      for (final st in a.steps) {
        if (!screenIds.contains(st.screenId)) {
          throw FeatureMapException(
            '${a.actionId}: 단계 화면 ${st.screenId}가 맵에 없다',
          );
        }
      }
    }
  }
}

class AppGuide {
  const AppGuide({
    required this.packageName,
    required this.locale,
    this.versionMin,
    this.versionMax,
    required this.screens,
    required this.actions,
  });

  final String packageName;
  final String locale;
  final String? versionMin, versionMax;
  final List<ScreenDef> screens;
  final List<ActionDef> actions;

  factory AppGuide._fromJson(Map<String, Object?> j) => AppGuide(
    packageName: _str(j, 'packageName'),
    locale: j['locale'] == null ? 'ko-KR' : _str(j, 'locale'),
    versionMin: _strOrNull(j, 'versionMin'),
    versionMax: _strOrNull(j, 'versionMax'),
    screens: _list(
      j,
      'screens',
      minItems: 1,
    ).map((e) => ScreenDef._fromJson(_obj(e, 'screens[]'))).toList(),
    actions: _list(
      j,
      'actions',
    ).map((e) => ActionDef._fromJson(_obj(e, 'actions[]'))).toList(),
  );
}

/// 화면 하나: 식별 글자(앵커) 목록. 채널 JSON의 `guidance.screens[]`와 같은 이름.
class ScreenDef {
  const ScreenDef({required this.screenId, required this.anchors});

  final String screenId;
  final List<String> anchors;

  factory ScreenDef._fromJson(Map<String, Object?> j) {
    final id = _id(j, 'screenId');
    final anchors = _list(
      j,
      'anchors',
      minItems: 2,
    ).map((e) => _text(e, '$id 앵커')).toList();
    for (final a in anchors) {
      for (final b in anchors) {
        if (a != b && b.contains(a)) {
          throw FeatureMapException('$id: 앵커 "$a"가 "$b" 안에 들어 있다 (서로 포함 금지)');
        }
      }
    }
    if (anchors.toSet().length != anchors.length) {
      throw FeatureMapException('$id: 앵커가 겹친다');
    }
    return ScreenDef(screenId: id, anchors: anchors);
  }
}

class ActionDef {
  const ActionDef({
    required this.actionId,
    required this.title,
    required this.description,
    required this.supportLevel,
    required this.steps,
  });

  final String actionId;
  final String title;
  final String description;

  /// 'verified' | 'draft'
  final String supportLevel;
  final List<StepDef> steps;

  /// 시작 화면 = 첫 단계의 화면. 파일에 따로 적지 않아 두 값이 어긋날 수 없다.
  String get screenId => steps.first.screenId;

  factory ActionDef._fromJson(Map<String, Object?> j) {
    final id = _id(j, 'actionId');
    final level = j['supportLevel'] == null ? 'draft' : _str(j, 'supportLevel');
    if (level != 'verified' && level != 'draft') {
      throw FeatureMapException('$id: supportLevel은 verified 또는 draft');
    }
    final steps = _list(
      j,
      'steps',
      minItems: 1,
    ).map((e) => StepDef._fromJson(_obj(e, '$id steps[]'), id)).toList();
    if (steps.length > 5) throw FeatureMapException('$id: 단계는 5개 이하 (D1~D5)');
    return ActionDef(
      actionId: id,
      title: _str(j, 'title', nonEmpty: true),
      description: _str(j, 'description'),
      supportLevel: level,
      steps: steps,
    );
  }

  GuideAction toGuideAction() => GuideAction(
    actionId: actionId,
    screenId: screenId,
    title: title,
    description: description,
    steps: [for (final s in steps) s.toGuideStep()],
  );
}

class StepDef {
  const StepDef({
    required this.screenId,
    required this.selector,
    required this.instruction,
    required this.result,
  });

  final String screenId;
  final String selector;
  final String instruction;
  final String result;

  factory StepDef._fromJson(Map<String, Object?> j, String actionId) {
    final selector = _str(j, 'selector');
    if (selector.trim().length < 2) {
      throw FeatureMapException('$actionId: 선택자 "$selector"는 2자 이상이어야 한다');
    }
    return StepDef(
      screenId: _id(j, 'screenId'),
      selector: selector,
      instruction: _str(j, 'instruction', nonEmpty: true),
      result: _str(j, 'result'),
    );
  }

  GuideStep toGuideStep() => GuideStep(
    screenId: screenId,
    selector: selector,
    instruction: instruction,
    result: result,
  );
}

/// 맵 파일이 형식이나 규칙을 어김. 읽는 코드 안에서만 쓰이고, 저장소가 잡아서 밖으로 내보내지 않는다.
class FeatureMapException implements Exception {
  const FeatureMapException(this.message);
  final String message;

  @override
  String toString() => 'FeatureMapException: $message';
}

// ── 읽기 도우미: 빠진 필드·틀린 타입이면 어디가 틀렸는지 적어 거부한다 ──

final _idPattern = RegExp(r'^[a-z0-9_]+\.[a-z0-9_]+$');

Map<String, Object?> _obj(Object? v, String where) {
  if (v is Map<String, Object?>) return v;
  throw FeatureMapException('$where: 객체가 아니다');
}

Object? _req(Map<String, Object?> j, String key) {
  if (!j.containsKey(key) || j[key] == null) {
    throw FeatureMapException('필수 필드 "$key"가 없다');
  }
  return j[key];
}

String _str(Map<String, Object?> j, String key, {bool nonEmpty = false}) {
  final v = _req(j, key);
  if (v is! String) throw FeatureMapException('"$key"는 문자열이어야 한다');
  if (nonEmpty && v.trim().isEmpty) throw FeatureMapException('"$key"가 비어 있다');
  return v;
}

String? _strOrNull(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v == null) return null;
  if (v is! String) throw FeatureMapException('"$key"는 문자열 또는 null이어야 한다');
  return v;
}

int _int(Map<String, Object?> j, String key) {
  final v = _req(j, key);
  if (v is! int) throw FeatureMapException('"$key"는 정수여야 한다');
  return v;
}

List<Object?> _list(Map<String, Object?> j, String key, {int minItems = 0}) {
  final v = _req(j, key);
  if (v is! List) throw FeatureMapException('"$key"는 목록이어야 한다');
  if (v.length < minItems) {
    throw FeatureMapException('"$key"는 $minItems개 이상이어야 한다');
  }
  return v;
}

String _id(Map<String, Object?> j, String key) {
  final v = _str(j, key);
  if (!_idPattern.hasMatch(v)) {
    throw FeatureMapException('"$key" 값 "$v"는 영역.이름 형식(소문자·숫자·_)이어야 한다');
  }
  return v;
}

String _text(Object? v, String where) {
  if (v is! String || v.trim().isEmpty) {
    throw FeatureMapException('$where: 빈 글자');
  }
  return v;
}
