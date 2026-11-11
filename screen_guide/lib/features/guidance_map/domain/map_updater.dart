enum MapUpdateStatus { upToDate, updated, offline, rejected }

class MapUpdateResult {
  const MapUpdateResult(this.status, this.revision);
  final MapUpdateStatus status;

  /// 결과 뒤의 활성 revision. 실패하면 이전 값 그대로.
  final String revision;
}

/// 포트: 기능 맵 갱신 (B01/B02). ── 제공: 팀원 3 (Firebase) / 사용: 팀원 2 (앱 시작 시 mapCheck)
///
/// 새 revision 확인 → 다운로드 → 해시·서명·스키마 검증 → 원자 교체. 어떤 실패든 이전 revision을 유지하고
/// 안내는 계속된다 (BE 6.3). 화면은 결과를 막지 않고, 설정 화면에서 revision만 보여 준다.
abstract interface class MapUpdater {
  Future<MapUpdateResult> checkForUpdate();
}
