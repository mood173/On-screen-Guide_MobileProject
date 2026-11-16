// ignore_for_file: prefer_initializing_formals

import 'package:flutter/services.dart';

import 'package:screen_guide/features/guidance_map/data/feature_map.dart';
import 'package:screen_guide/features/guidance_map/domain/guidance.dart';
import 'package:screen_guide/shared/contracts/analysis.dart';

/// 맵 파일 글을 읽는 함수. 기본은 앱 에셋, 시험에서는 바꿔 끼운다.
typedef MapSource = Future<String> Function();

/// [GuidanceRepository]의 진짜 구현. ── 최정혁 (협업규격_최종 4.3 #1)
///
/// 앱에 든 JSON 기능 맵(`assets/feature_maps/`)을 처음 쓸 때 한 번 읽어 메모리에 둔다.
/// 대상 앱 1~2개·기능 3개라 DB 대신 JSON으로 둔다 (일정_현실검토 3-2 [제안]).
///
/// 예외를 밖으로 던지지 않는다. 맵을 읽지 못하거나 규칙을 어기면 **빈 맵**으로 답한다
/// (화면 0개 → 분석은 UNKNOWN_SCREEN → "다시 촬영해 주세요"). 앱에 든 맵이 깨지는 것은
/// 만들 때의 실수이므로 `test/features/guidance_map/`의 시험이 먼저 잡는다.
class AssetGuidanceRepository implements GuidanceRepository {
  AssetGuidanceRepository({this.asset = defaultAsset, MapSource? source})
    : _source = source;

  static const defaultAsset = 'assets/feature_maps/sample_v1.json';

  /// 읽지 못했을 때의 revision 표시
  static const unavailableRevision = 'unavailable';

  final String asset;
  final MapSource? _source;
  Future<FeatureMap?>? _loading;

  /// 마지막으로 읽기에 실패한 이유 (설정 화면·디버깅용). 성공하면 null.
  String? loadError;

  Future<FeatureMap?> _map() => _loading ??= _load();

  Future<FeatureMap?> _load() async {
    try {
      final text = await (_source?.call() ?? rootBundle.loadString(asset));
      final map = FeatureMap.parse(text);
      loadError = null;
      return map;
    } catch (e) {
      loadError = e.toString();
      return null;
    }
  }

  @override
  Future<GuidanceFragment> fragment() async =>
      (await _map())?.toFragment() ??
      const GuidanceFragment(packageName: '', screens: []);

  @override
  Future<List<GuideAction>> actionsFor(String screenId) async {
    final map = await _map();
    if (map == null) return const [];
    return [
      for (final a in map.actions)
        if (a.screenId == screenId) a.toGuideAction(),
    ];
  }

  @override
  Future<String> activeRevision() async =>
      (await _map())?.revision ?? unavailableRevision;
}
