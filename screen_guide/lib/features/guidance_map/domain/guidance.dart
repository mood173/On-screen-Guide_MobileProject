import 'package:screen_guide/shared/contracts/analysis.dart';

/// 안내 한 단계. (기능·개념 정리 9.2 guidance_maps의 steps 한 칸)
class GuideStep {
  const GuideStep({
    required this.selector,
    required this.instruction,
    required this.result,
  });

  /// 이 단계에서 누를 UI의 글자. Kotlin 대상 찾기 요청의 target.selector로 그대로 넘어간다.
  final String selector;

  /// 안내 카드 제목 ("알림 설정을 눌러주세요")
  final String instruction;

  /// 누르면 일어나는 일 (안내 카드 보조 문구)
  final String result;
}

/// 안내할 수 있는 기능 하나. (guidance_maps의 action 한 건)
class GuideAction {
  const GuideAction({
    required this.actionId,
    required this.screenId,
    required this.title,
    required this.description,
    required this.steps,
  });

  /// 앱 기능 ID (영역.동작, 계약 v1 결정 2)
  final String actionId;

  /// 이 기능을 시작할 수 있는 화면 (분석 응답의 screenId와 같은 값)
  final String screenId;
  final String title;
  final String description;
  final List<GuideStep> steps;
}

/// 포트: 기능 맵 조회. ── 제공: 팀원 3 (데이터·입출력) / 사용: 팀원 2 (흐름), 간접적으로 팀원 1 (Kotlin)
///
/// 기능 맵의 유일한 원본은 Flutter 쪽 이 저장소다 (계약 v1 결정 1).
/// 구현: DemoGuidanceRepository(체험용, 지금) → 로컬 DB 구현(3주차) → Firebase 갱신 반영(4주차)
/// 진짜 구현은 test/ports/guidance_repository_contract.dart 공용 시험을 통과해야 연결한다.
abstract interface class GuidanceRepository {
  /// 분석 요청에 함께 넣을 맵 조각: 지원하는 모든 화면의 screenId와 앵커.
  Future<GuidanceFragment> fragment();

  /// 식별된 화면에서 안내할 수 있는 기능 목록. 없으면 빈 목록.
  Future<List<GuideAction>> actionsFor(String screenId);

  /// 지금 쓰는 기능 맵 revision. 설정 화면 표시와 이력 기록에 쓴다.
  Future<String> activeRevision();
}
