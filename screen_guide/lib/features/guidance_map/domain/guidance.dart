import 'package:screen_guide/shared/contracts/analysis.dart';

/// 안내 한 단계. (협업규격_최종 3.2)
class GuideStep {
  const GuideStep({
    required this.screenId,
    required this.selector,
    required this.instruction,
    required this.result,
  });

  /// 이 단계를 하는 화면 (맵 조각에 있는 화면 ID). 단계가 다른 화면에 걸칠 수 있다 (기능별_검토_결론 4-2).
  /// 첫 단계의 화면 = 기능의 시작 화면.
  final String screenId;

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

/// 포트: 기능 맵 조회. ── 구현: 최정혁 / 사용: 지형주 (흐름), 간접적으로 강민준 (Kotlin)
///
/// 기능 맵의 유일한 원본은 Flutter 쪽 이 저장소다 (계약 v1 결정 1).
/// 구현: DemoGuidanceRepository(체험용, 지금) → 실제 앱 기능 맵(11/27) → Firebase 갱신 반영(선택, 12/2)
/// 진짜 구현은 test/ports/port_contracts.dart의 guidanceRepositoryContract(맵 규칙)를 통과해야 연결한다.
abstract interface class GuidanceRepository {
  /// 분석 요청에 함께 넣을 맵 조각: 지원하는 모든 화면의 screenId와 앵커.
  Future<GuidanceFragment> fragment();

  /// 식별된 화면에서 안내할 수 있는 기능 목록. 없으면 빈 목록.
  Future<List<GuideAction>> actionsFor(String screenId);

  /// 지금 쓰는 기능 맵 revision. 설정 화면 표시와 이력 기록에 쓴다.
  Future<String> activeRevision();
}
