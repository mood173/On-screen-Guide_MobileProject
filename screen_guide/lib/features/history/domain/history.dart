/// 안내 기록 한 건. 원본 이미지·OCR 원문·개인정보 후보 원문은 담지 않는다 (명세 C03, 설계 9.1).
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.actionId,
    required this.actionTitle,
    required this.stepInstructions,
    required this.input,
    required this.createdAt,
    this.piiTypes = const [],
  });

  final String id;

  /// 앱 기능 ID — 동의 시 서버 동기화되는 것은 actionId·단계 수·시각뿐이다 (설계 9.1).
  final String actionId;
  final String actionTitle;

  /// 단계별 안내 문구 ("알림 설정을 눌러주세요" …) — 사용 방법 다시 보기·공유에 쓴다.
  final List<String> stepInstructions;

  /// 입력 방식: gallery / camera / sample
  final String input;
  final DateTime createdAt;

  /// 개인정보 후보 유형 이름만 (가린 값·원문 없음)
  final List<String> piiTypes;
}

/// 포트: 안내 기록. ── 제공: 팀원 3 / 사용: 팀원 2 (DONE "안내 기록에 저장", HISTORY 화면)
///
/// 구현: InMemoryHistoryRepository(지금) → 로컬 DB(3주차) → 동의 시 Firebase 동기화(4주차, 선택)
abstract interface class HistoryRepository {
  Future<void> save(HistoryEntry entry);

  /// 최근 것부터
  Future<List<HistoryEntry>> list();
  Future<HistoryEntry?> get(String id);
  Future<void> delete(String id);
}
