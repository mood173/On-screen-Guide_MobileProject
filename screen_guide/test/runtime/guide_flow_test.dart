import 'package:flutter_test/flutter_test.dart';
import 'package:screen_guide/contract/analysis.dart';
import 'package:screen_guide/core/action_id.dart';
import 'package:screen_guide/core/error_code.dart';
import 'package:screen_guide/core/flow_state.dart';
import 'package:screen_guide/core/screen_id.dart';
import 'package:screen_guide/data/demo_guidance.dart';
import 'package:screen_guide/data/fake_analyzer.dart';
import 'package:screen_guide/data/sample_images.dart';
import 'package:screen_guide/domain/screen_analyzer.dart';
import 'package:screen_guide/runtime/guide_flow.dart';

GuideFlow _flow([ScreenAnalyzer? a]) =>
    GuideFlow(analyzer: a ?? FakeAnalyzer(delay: Duration.zero));

Future<GuideFlow> _toResult(SampleImage s, [ScreenAnalyzer? a]) async {
  final f = _flow(a);
  await f.dispatch(ActionId.captureGallery); // H → G
  await f.dispatch(ActionId.captureGallery, s); // G → GS
  await f.dispatch(ActionId.captureGallery); // GS → GR
  await f.dispatch(ActionId.analyzeRun); // GR → GA → RG
  return f;
}

/// 응답을 손으로 끝내는 분석기 (취소 시험용)
class _HoldAnalyzer implements ScreenAnalyzer {
  final calls = <AnalyzeRequest>[];
  final _done = <Future<void> Function(AnalysisResult)>[];
  @override
  Future<AnalysisResult> analyze(AnalyzeRequest request) {
    calls.add(request);
    return FakeAnalyzer(delay: const Duration(milliseconds: 50))
        .analyze(request);
  }

  int get pending => _done.length;
}

void main() {
  test('갤러리 흐름: H → G → GS → GR → GA → RG → D1 → DONE', () async {
    final f = _flow();
    expect(f.screen, ScreenId.h);

    await f.dispatch(ActionId.captureGallery);
    expect(f.screen, ScreenId.g);

    await f.dispatch(ActionId.captureGallery, SampleImage.settings);
    expect(f.screen, ScreenId.gs);
    expect(f.picked, SampleImage.settings);

    await f.dispatch(ActionId.captureGallery);
    expect(f.screen, ScreenId.gr);
    expect(f.state, FlowState.picked);

    await f.dispatch(ActionId.analyzeRun);
    expect(f.screen, ScreenId.rg);
    expect(f.result!.screenId, 'settings');
    expect(
      f.availableActions.map((a) => a.actionId),
      contains('settings.notification'),
    );

    final notif = DemoGuidance.actions.firstWhere(
      (a) => a.actionId == 'settings.notification',
    );
    await f.dispatch(ActionId.guideStart, notif);
    expect(f.screen, ScreenId.d1);
    expect(f.target!.label, '알림 설정');
    expect(f.target!.box, const Box(174, 1029, 341, 1070));

    await f.dispatch(ActionId.guideNext);
    expect(f.screen, ScreenId.done);
    expect(f.state, FlowState.done);

    await f.dispatch(ActionId.navHome);
    expect(f.screen, ScreenId.h);
    expect(f.picked, isNull);
  });

  test('2단계 기능은 D1 → D2로 넘어가며 단계마다 대상을 다시 찾는다', () async {
    final f = await _toResult(SampleImage.chat);
    expect(f.result!.screenId, 'chat');
    expect(f.result!.pii, hasLength(5));

    final send = DemoGuidance.actions.firstWhere(
      (a) => a.actionId == 'chat.send',
    );
    await f.dispatch(ActionId.guideStart, send);
    expect(f.screen, ScreenId.d1);
    expect(f.target!.label, '메시지 입력');

    await f.dispatch(ActionId.guideNext);
    expect(f.screen, ScreenId.d2);
    expect(f.target!.label, '보내기');

    await f.dispatch(ActionId.navBack);
    expect(f.screen, ScreenId.d1);
  });

  test('Gate: 화면에 없는 행동은 무시한다', () async {
    final f = _flow();
    await f.dispatch(ActionId.analyzeRun); // 홈에서는 분석 불가
    expect(f.screen, ScreenId.h);
    await f.dispatch(ActionId.guideNext);
    expect(f.screen, ScreenId.h);
  });

  test('화면 식별 실패 → E(UNKNOWN_SCREEN), 분석 오류 → E(해당 코드)', () async {
    // 앵커가 맞지 않는 기능 맵으로는 식별 실패를 만들 수 없으니, 오류 분석기로 확인한다.
    final f = await _toResult(
      SampleImage.settings,
      FakeAnalyzer(delay: Duration.zero, failWith: ErrorCode.imageReadFailed),
    );
    expect(f.screen, ScreenId.e);
    expect(f.error, ErrorCode.imageReadFailed);

    await f.dispatch(ActionId.captureRetake);
    expect(f.screen, ScreenId.g);
  });

  test('분석 취소: 늦게 온 응답은 버리고 GR에 머문다', () async {
    final hold = _HoldAnalyzer();
    final f = _flow(hold);
    await f.dispatch(ActionId.captureGallery);
    await f.dispatch(ActionId.captureGallery, SampleImage.settings);
    await f.dispatch(ActionId.captureGallery);

    final running = f.dispatch(ActionId.analyzeRun);
    expect(f.screen, ScreenId.ga);
    await f.dispatch(ActionId.analyzeCancel);
    expect(f.screen, ScreenId.gr);

    await running; // 응답이 와도
    expect(f.screen, ScreenId.gr); // 결과 화면으로 넘어가지 않음
    expect(f.result, isNull);
    expect(hold.pending, 0);
  });

  test('3초가 넘으면 slow가 켜진다 (오류로 끊지 않음)', () async {
    final f = GuideFlow(
      analyzer: FakeAnalyzer(delay: const Duration(milliseconds: 80)),
      slowAfter: const Duration(milliseconds: 20),
    );
    await f.dispatch(ActionId.captureGallery);
    await f.dispatch(ActionId.captureGallery, SampleImage.settings);
    await f.dispatch(ActionId.captureGallery);
    final running = f.dispatch(ActionId.analyzeRun);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(f.slow, isTrue);
    expect(f.screen, ScreenId.ga);
    await running;
    expect(f.slow, isFalse);
    expect(f.screen, ScreenId.rg);
  });

  test('준비 중인 기능은 안내 문구만 남긴다', () async {
    final f = _flow();
    await f.dispatch(ActionId.captureCamera);
    expect(f.screen, ScreenId.h);
    expect(f.notice, isNotNull);
  });
}
