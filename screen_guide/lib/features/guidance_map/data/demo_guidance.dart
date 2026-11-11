// 체험용 기능 맵 (샘플 이미지 2장용). 최정혁의 실제 앱 기능 맵 구현이 들어오면 bootstrap에서 교체한다.
//
// 협업규격_최종 3.2의 맵 규칙을 지킨다: 화면 ID는 앱.화면, 화면마다 앵커 2개 이상(서로 포함하지 않음),
// 기능마다 단계 1~5개, 단계의 screenId는 맵 조각에 있는 화면, 선택자는 2자 이상.
// 규칙은 test/ports/port_contracts.dart의 guidanceRepositoryContract가 확인한다.

import 'package:screen_guide/features/guidance_map/domain/guidance.dart';
import 'package:screen_guide/shared/contracts/analysis.dart';

export 'package:screen_guide/features/guidance_map/domain/guidance.dart'
    show GuideAction, GuideStep;

/// 체험용 [GuidanceRepository] 구현.
class DemoGuidanceRepository implements GuidanceRepository {
  const DemoGuidanceRepository();

  @override
  Future<GuidanceFragment> fragment() async => DemoGuidance.fragment;

  @override
  Future<List<GuideAction>> actionsFor(String screenId) async =>
      DemoGuidance.forScreen(screenId);

  @override
  Future<String> activeRevision() async => 'demo';
}

abstract final class DemoGuidance {
  static const packageName = 'demo.screen_guide';

  static const fragment = GuidanceFragment(
    packageName: packageName,
    screens: [
      // 앵커끼리 서로 포함하지 않는다: '설정'은 '알림 설정'·'설정 검색' 안에 들어 있어 쓰지 않는다 (협업규격_최종 3.2)
      ScreenAnchors(
        screenId: 'demo.settings',
        anchors: ['네트워크 및 인터넷', '알림 설정', '배터리', '디스플레이'],
      ),
      ScreenAnchors(screenId: 'demo.chat', anchors: ['대화', '메시지 입력', '보내기']),
    ],
  );

  static const actions = [
    GuideAction(
      actionId: 'settings.notification',
      screenId: 'demo.settings',
      title: '알림 설정 바꾸기',
      description: '앱별 알림을 켜고 끄는 화면으로 가요',
      steps: [
        GuideStep(
          screenId: 'demo.settings',
          selector: '알림 설정',
          instruction: '알림 설정을 눌러주세요',
          result: '앱별 알림을 켜고 끌 수 있는 화면이 열려요.',
        ),
      ],
    ),
    GuideAction(
      actionId: 'settings.display',
      screenId: 'demo.settings',
      title: '글자 크기 바꾸기',
      description: '디스플레이에서 글꼴 크기를 바꿔요',
      steps: [
        GuideStep(
          screenId: 'demo.settings',
          selector: '디스플레이',
          instruction: '디스플레이를 눌러주세요',
          result: '어두운 테마와 글꼴 크기를 바꾸는 화면이 열려요.',
        ),
      ],
    ),
    GuideAction(
      actionId: 'chat.send',
      screenId: 'demo.chat',
      title: '메시지 보내기',
      description: '대화방에서 메시지를 적어 보내요',
      steps: [
        GuideStep(
          screenId: 'demo.chat',
          selector: '메시지 입력',
          instruction: '메시지 입력 칸을 눌러주세요',
          result: '키보드가 열리면 보낼 내용을 적어요.',
        ),
        GuideStep(
          screenId: 'demo.chat',
          selector: '보내기',
          instruction: '보내기를 눌러주세요',
          result: '적은 메시지가 상대에게 전달돼요.',
        ),
      ],
    ),
  ];

  static List<GuideAction> forScreen(String? screenId) =>
      actions.where((a) => a.screenId == screenId).toList();
}
