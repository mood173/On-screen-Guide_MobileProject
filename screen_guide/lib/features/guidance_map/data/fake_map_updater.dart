// 최정혁(데이터·입출력)이 진짜 구현을 넣기 전까지 쓰는 가짜 구현. app/bootstrap.dart에서 진짜로 바꿔 끼운다.

import 'package:screen_guide/features/guidance_map/domain/map_updater.dart';

/// 가짜 기능 맵 갱신: 항상 최신이라고 답한다.
class FakeMapUpdater implements MapUpdater {
  @override
  Future<MapUpdateResult> checkForUpdate() async =>
      const MapUpdateResult(MapUpdateStatus.upToDate, 'demo');
}
