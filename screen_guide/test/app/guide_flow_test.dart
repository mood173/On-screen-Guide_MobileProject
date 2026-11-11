import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/analyze/data/fake_analyzer.dart';
import 'package:screen_guide/features/analyze/domain/screen_analyzer.dart';
import 'package:screen_guide/features/capture/data/fake_input.dart';
import 'package:screen_guide/features/capture/data/image_files.dart';
import 'package:screen_guide/features/capture/data/sample_images.dart';
import 'package:screen_guide/features/guidance_map/data/demo_guidance.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/guidance_map/domain/guidance.dart';
import 'package:screen_guide/features/history/data/in_memory_history_repository.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/contracts/analysis.dart';
import 'package:screen_guide/shared/contracts/error_code.dart';
import 'package:screen_guide/shared/contracts/flow_state.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';

import '../support/test_flow.dart';

GuideFlow _flow([ScreenAnalyzer? a]) => testFlow(analyzer: a);

/// H → G → GS → GR: 갤러리를 열고, 한 칸을 고르고, 사용한다.
Future<void> _pickSample(GuideFlow f, SampleImage s) async {
  await f.dispatch(ActionId.captureGallery); // H → G
  await f.dispatch(ActionId.capturePick, s.id); // G → GS
  await f.dispatch(ActionId.captureConfirm); // GS → GR
}

Future<GuideFlow> _toResult(SampleImage s, [ScreenAnalyzer? a]) async {
  final f = _flow(a);
  await _pickSample(f, s);
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

class _OneActionRepo implements GuidanceRepository {
  @override
  Future<GuidanceFragment> fragment() async => DemoGuidance.fragment;
  @override
  Future<List<GuideAction>> actionsFor(String screenId) async => const [
    GuideAction(
      actionId: 'settings.battery',
      screenId: 'settings',
      title: '배터리 확인',
      description: '배터리 사용량을 봐요',
      steps: [
        GuideStep(
          screenId: 'settings',
          selector: '배터리',
          instruction: '배터리를 눌러주세요',
          result: '',
        ),
      ],
    ),
  ];
  @override
  Future<String> activeRevision() async => 't';
}

class _RecordingFiles implements ImageFiles {
  final released = <String>[];
  var _n = 0;
  @override
  Future<String> prepare(SampleImage sample) async =>
      '/cache/sg_${++_n}/${sample.asset.split('/').last}';
  @override
  Future<void> release(String path) async => released.add(path);
  @override
  Future<void> clearLeftovers() async {}
}

void main() {
  test('갤러리 흐름: H → G → GS → GR → GA → RG → D1 → DONE', () async {
    final f = _flow();
    expect(f.screen, ScreenId.h);

    await f.dispatch(ActionId.captureGallery);
    expect(f.screen, ScreenId.g);
    expect(f.galleryItems.map((e) => e.id), ['settings', 'chat']);

    await f.dispatch(ActionId.capturePick, 'settings');
    expect(f.screen, ScreenId.gs);
    expect(f.selectedId, 'settings');

    await f.dispatch(ActionId.captureConfirm);
    expect(f.screen, ScreenId.gr);
    expect(f.state, FlowState.picked);
    expect(f.picked!.path, 'assets/samples/sample_settings.png');
    expect(f.picked!.input, InputKind.gallery);

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
    await _pickSample(f, SampleImage.settings);

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
    final f = testFlow(
      analyzer: FakeAnalyzer(delay: const Duration(milliseconds: 80)),
      slowAfter: const Duration(milliseconds: 20),
    );
    await _pickSample(f, SampleImage.settings);
    final running = f.dispatch(ActionId.analyzeRun);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(f.slow, isTrue);
    expect(f.screen, ScreenId.ga);
    await running;
    expect(f.slow, isFalse);
    expect(f.screen, ScreenId.rg);
  });

  test('분석 요청에는 복사본 파일 경로가 들어가고, 홈으로 가면 복사본을 지운다', () async {
    final files = _RecordingFiles();
    final hold = _HoldAnalyzer();
    final f = testFlow(analyzer: hold, files: files);
    await _pickSample(f, SampleImage.chat);
    await f.dispatch(ActionId.analyzeRun);

    expect(hold.calls.single.imagePath, '/cache/sg_1/sample_chat.png');
    expect(f.result!.screenId, 'chat', reason: '가짜 분석기는 파일 이름으로 샘플을 찾는다');

    await f.dispatch(ActionId.navHome);
    expect(files.released, ['/cache/sg_1/sample_chat.png']);
  });

  test('완료 화면에서 안내 기록 저장 → HistoryRepository에 원문 없이 저장된다', () async {
    final history = InMemoryHistoryRepository();
    final f = testFlow(history: history);
    await _pickSample(f, SampleImage.chat);
    await f.dispatch(ActionId.analyzeRun);
    final send = f.availableActions.single;
    await f.dispatch(ActionId.guideStart, send);
    await f.dispatch(ActionId.guideNext);
    await f.dispatch(ActionId.guideNext);
    expect(f.screen, ScreenId.done);

    await f.dispatch(ActionId.historySave);
    final saved = (await f.historyList()).single;
    expect(saved.actionId, 'chat.send');
    expect(saved.stepInstructions, hasLength(2));
    expect(saved.piiTypes, hasLength(5));
    expect(
      saved.piiTypes.join(),
      isNot(contains('010')),
      reason: '유형 이름만, 가린 값·원문 없음',
    );
    expect(saved.input, InputKind.gallery);
    expect(saved.createdAt, DateTime(2026, 11, 20, 10));
    expect(f.notice, '안내 기록에 저장했어요');
  });

  test('기능 목록은 GuidanceRepository에서 온다', () async {
    final f = testFlow(guidance: _OneActionRepo());
    await _pickSample(f, SampleImage.settings);
    await f.dispatch(ActionId.analyzeRun);
    expect(f.availableActions.map((a) => a.actionId), ['settings.battery']);
  });

  test('준비 중인 기능은 안내 문구만 남긴다', () async {
    final f = _flow();
    await f.dispatch(ActionId.captureCamera);
    expect(f.screen, ScreenId.h);
    expect(f.notice, isNotNull);
  });

  test(
    '갤러리 권한 거부 → 오류 화면(PERMISSION_DENIED), 다른 이미지를 고르면 앞 복사본을 지운다',
    () async {
      final denied = testFlow(
        gallery: FakeGalleryInput(
          access: PickStatus.permissionDenied,
          loadThumbnail: noThumbnail,
        ),
      );
      await denied.dispatch(ActionId.captureGallery);
      expect(denied.screen, ScreenId.e);
      expect(denied.error, ErrorCode.permissionDenied);

      final files = _RecordingFiles();
      final f = testFlow(files: files);
      await _pickSample(f, SampleImage.settings);
      await f.dispatch(ActionId.captureRetake); // GR → G
      expect(f.screen, ScreenId.g);
      expect(files.released, ['/cache/sg_1/sample_settings.png']);
      expect(f.picked, isNull);
    },
  );

  test('준비 단계: start()가 남은 복사본 청소를 부른다', () async {
    final cleanup = _RecordingCleanup();
    testFlow(cleanup: cleanup).start();
    await Future<void>.delayed(Duration.zero);
    expect(cleanup.cleared, 1);
  });

  test('관문: 홈 탭은 화면 이동 ID, 결과 화면에서는 저장·공유를 열지 않는다', () async {
    final f = _flow();
    expect(f.allows(ActionId.navHistory), isTrue);
    expect(f.allows(ActionId.navSettings), isTrue);
    expect(
      f.allows(ActionId.historyOpen),
      isFalse,
      reason: '기록 한 건 열기는 기록 화면에서',
    );
    expect(f.allows(ActionId.settingsOpenPermission), isFalse);

    await _pickSample(f, SampleImage.settings);
    await f.dispatch(ActionId.analyzeRun);
    expect(f.screen, ScreenId.rg);
    expect(f.allows(ActionId.sharePrepare), isFalse, reason: 'X1');
    expect(f.allows(ActionId.historySave), isFalse, reason: 'X1');
    expect(f.allows(ActionId.captureRetake), isTrue);
  });

  test('복구: 갤러리 세션의 오류 화면은 다시 고르기로 목록에 돌아간다', () async {
    final f = await _toResult(
      SampleImage.settings,
      FakeAnalyzer(delay: Duration.zero, failWith: ErrorCode.analysisFailed),
    );
    expect(f.screen, ScreenId.e);
    expect(f.input, InputKind.gallery);
    expect(f.allows(ActionId.overlayRescan), isFalse);
    await f.dispatch(ActionId.captureRetake);
    expect(f.screen, ScreenId.g);
  });
}

class _RecordingCleanup implements InputCleanup {
  var cleared = 0;
  @override
  Future<void> clearLeftovers() async => cleared++;
  @override
  Future<void> openAppSettings() async {}
  @override
  Future<void> release(PickedImage image) async {}
}
