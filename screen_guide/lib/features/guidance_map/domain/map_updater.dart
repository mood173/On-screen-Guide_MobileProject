enum MapUpdateStatus { upToDate, updated, offline, rejected }

class MapUpdateResult {
  const MapUpdateResult(this.status, this.revision);
  final MapUpdateStatus status;

  /// 결과 뒤의 활성 revision. 실패하면 이전 값 그대로.
  final String revision;
}

/// 포트: 기능 맵 갱신 (B01/B02). ── 구현: 최정혁 (Firebase, 선택) / 사용: 지형주 (앱 시작 시 GuideFlow.start)
///
/// 새 revision 확인 → 다운로드 → 해시·서명·스키마 검증 → 원자 교체. 어떤 실패든 이전 revision을 유지하고
/// 안내는 계속된다 (BE 6.3). 화면은 결과를 막지 않고, 설정 화면에서 revision만 보여 준다.
abstract interface class MapUpdater {
  Future<MapUpdateResult> checkForUpdate();
}
