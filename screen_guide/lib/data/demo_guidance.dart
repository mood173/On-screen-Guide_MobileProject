// 체험용 기능 맵. 데이터 담당의 기능 맵 스키마·GuidanceRepository가 들어오면 이 파일을 교체한다.
//
// 형식은 기능·개념 정리 9.2의 guidance_maps(screen_id, screen_anchors, action_id, utterances, selectors, steps)를
// 화면에 필요한 만큼만 줄인 것이다.

import '../contract/analysis.dart';

class GuideStep {
  const GuideStep({
    required this.selector,
    required this.instruction,
    required this.result,
  });

  /// 이 단계에서 누를 UI의 글자 (Kotlin 대상 찾기에 넘김)
  final String selector;

  /// 안내 카드 제목 ("알림 설정을 눌러주세요")
  final String instruction;

  /// 누르면 일어나는 일 (안내 카드 보조 문구)
  final String result;
}

class GuideAction {
  const GuideAction({
    required this.actionId,
    required this.screenId,
    required this.title,
    required this.description,
    required this.steps,
  });

  /// 앱 기능 ID (영역.동작)
  final String actionId;

  /// 이 기능을 시작할 수 있는 화면
  final String screenId;
  final String title;
  final String description;
  final List<GuideStep> steps;
}

abstract final class DemoGuidance {
  static const packageName = 'demo.screen_guide';

  static const fragment = GuidanceFragment(
    packageName: packageName,
    screens: [
      ScreenAnchors(
        screenId: 'settings',
        anchors: ['설정', '알림 설정', '배터리', '디스플레이'],
      ),
      ScreenAnchors(screenId: 'chat', anchors: ['대화', '메시지 입력', '보내기']),
    ],
  );

  static const actions = [
    GuideAction(
      actionId: 'settings.notification',
      screenId: 'settings',
      title: '알림 설정 바꾸기',
      description: '앱별 알림을 켜고 끄는 화면으로 가요',
      steps: [
        GuideStep(
          selector: '알림 설정',
          instruction: '알림 설정을 눌러주세요',
          result: '앱별 알림을 켜고 끌 수 있는 화면이 열려요.',
        ),
      ],
    ),
    GuideAction(
      actionId: 'settings.display',
      screenId: 'settings',
      title: '글자 크기 바꾸기',
      description: '디스플레이에서 글꼴 크기를 바꿔요',
      steps: [
        GuideStep(
          selector: '디스플레이',
          instruction: '디스플레이를 눌러주세요',
          result: '어두운 테마와 글꼴 크기를 바꾸는 화면이 열려요.',
        ),
      ],
    ),
    GuideAction(
      actionId: 'chat.send',
      screenId: 'chat',
      title: '메시지 보내기',
      description: '대화방에서 메시지를 적어 보내요',
      steps: [
        GuideStep(
          selector: '메시지 입력',
          instruction: '메시지 입력 칸을 눌러주세요',
          result: '키보드가 열리면 보낼 내용을 적어요.',
        ),
        GuideStep(
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
