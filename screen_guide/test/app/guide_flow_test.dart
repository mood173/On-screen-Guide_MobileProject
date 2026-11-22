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
import 'package:screen_guide/features/history/domain/history.dart';
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
      screenId: 'demo.settings',
      title: '배터리 확인',
      description: '배터리 사용량을 봐요',
      steps: [
        GuideStep(
          screenId: 'demo.settings',
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

/// 진짜 카메라처럼: 열려 있는 동안 또 부르면 실패(readFailed). 호출 수를 센다.
class _SlowCamera implements CameraInput {
  var calls = 0;
  var _open = false;
  @override
  Future<PickedImage> takePhoto() async {
    calls++;
    if (_open) {
      return const PickedImage.failed(PickStatus.readFailed, InputKind.camera);
    }
    _open = true;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    _open = false;
    return const PickedImage(
      status: PickStatus.ok,
      path: '/cache/sg_cam/photo.png',
      input: InputKind.camera,
    );
  }
}

/// 갤러리 "사용"이 시간이 걸리는 가짜. 호출 수를 센다.
class _SlowGallery extends FakeGalleryInput {
  _SlowGallery() : super(loadThumbnail: noThumbnail);
  var useCalls = 0;
  @override
  Future<PickedImage> use(String id) async {
    useCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return super.use(id);
  }
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
    expect(f.result!.screenId, 'demo.settings');
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
    expect(f.result!.screenId, 'demo.chat');
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

  // 시스템설계 3-4 "나갈 때 타이머 정지" (_onExit)
  test('분석 중 뒤로(취소) → 시간이 지나도 slow가 켜지지 않는다 (3-4 나갈 때 타이머 정지)', () async {
    final f = testFlow(
      analyzer: FakeAnalyzer(delay: const Duration(milliseconds: 80)),
      slowAfter: const Duration(milliseconds: 20),
    );
    await _pickSample(f, SampleImage.settings);
    final running = f.dispatch(ActionId.analyzeRun);
    expect(f.screen, ScreenId.ga);
    await f.dispatch(ActionId.navBack); // 분석의 뒤로 = 취소
    expect(f.screen, ScreenId.gr);

    // slowAfter(20ms)가 지나도록 기다린다
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(f.slow, isFalse, reason: '타이머가 멈췄다');
    await running;
    expect(f.screen, ScreenId.gr, reason: '늦게 온 응답은 무시');
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
    expect(f.result!.screenId, 'demo.chat', reason: '가짜 분석기는 파일 이름으로 샘플을 찾는다');

    // 홈 버튼은 마무리·오류 화면에만 있다 (시스템설계_최종 3-7·3-9). 안내를 끝까지 진행한 뒤 홈으로.
    expect(f.allows(ActionId.navHome), isFalse, reason: '선택 단계에서는 홈 없음');
    await f.dispatch(ActionId.guideStart, f.availableActions.first);
    for (var i = 0; i < 5 && f.screen != ScreenId.done; i++) {
      await f.dispatch(ActionId.guideNext);
    }
    expect(f.screen, ScreenId.done);

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
    final saved = (await history.list()).single;
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

  // 시스템설계 3-9 기록·설정, 9장 "기록을 다시 본다 / 지운다" (협업규격 4.2 5번)
  group('기록 화면 (HISTORY)', () {
    HistoryEntry entry(String id, int hour) => HistoryEntry(
      id: id,
      actionId: 'chat.send',
      actionTitle: '메시지 보내기 $id',
      stepInstructions: const ['입력창을 누르세요', '보내기를 누르세요'],
      input: InputKind.gallery,
      createdAt: DateTime(2026, 11, 20, hour),
    );

    Future<(GuideFlow, InMemoryHistoryRepository)> withTwo() async {
      final history = InMemoryHistoryRepository();
      await history.save(entry('a', 9));
      await history.save(entry('b', 10));
      return (testFlow(history: history), history);
    }

    test('기록이 0건: 탭을 누르면 HISTORY, 목록은 비어 있다', () async {
      final f = _flow();
      await f.dispatch(ActionId.navHistory);
      expect(f.screen, ScreenId.history);
      expect(f.historyItems, isEmpty);
      expect(f.openedEntry, isNull);
    });

    test('여러 건: 최근 것부터 읽어 둔다', () async {
      final (f, _) = await withTwo();
      await f.dispatch(ActionId.navHistory);
      expect(f.historyItems.map((e) => e.id), ['b', 'a']);
    });

    test('다시 보기: 한 건을 펼치면 단계 문구가 있다, 뒤로 → 목록 → 홈', () async {
      final (f, _) = await withTwo();
      await f.dispatch(ActionId.navHistory);
      await f.dispatch(ActionId.historyOpen, 'a');
      expect(f.openedEntry?.id, 'a');
      expect(f.openedEntry?.stepInstructions, hasLength(2));

      await f.dispatch(ActionId.navBack); // 펼침 닫기
      expect(f.screen, ScreenId.history);
      expect(f.openedEntry, isNull);

      await f.dispatch(ActionId.navBack); // 목록 → 홈
      expect(f.screen, ScreenId.h);
    });

    test('지우기: 저장소에서 지우고 목록을 다시 읽는다', () async {
      final (f, history) = await withTwo();
      await f.dispatch(ActionId.navHistory);
      await f.dispatch(ActionId.historyDelete, 'b');
      expect(f.historyItems.map((e) => e.id), ['a']);
      expect(await history.get('b'), isNull);
    });

    test('펼쳐 둔 기록을 지우면 펼침이 닫힌다 / 다른 기록을 지우면 그대로', () async {
      final (f, _) = await withTwo();
      await f.dispatch(ActionId.navHistory);
      await f.dispatch(ActionId.historyOpen, 'a');
      await f.dispatch(ActionId.historyDelete, 'b');
      expect(f.openedEntry?.id, 'a', reason: '다른 기록을 지움');
      await f.dispatch(ActionId.historyDelete, 'a');
      expect(f.openedEntry, isNull, reason: '펼쳐 둔 기록을 지움');
      expect(f.historyItems, isEmpty);
    });

    test('이미 지워진 기록을 열면: 펼치지 않고 목록을 새로 읽는다', () async {
      final (f, history) = await withTwo();
      await f.dispatch(ActionId.navHistory);
      await history.delete('a'); // 화면 목록에는 아직 a가 있다
      await f.dispatch(ActionId.historyOpen, 'a');
      expect(f.openedEntry, isNull);
      expect(f.historyItems.map((e) => e.id), ['b']);
    });

    test('기록 화면을 떠나면 값을 비운다 (홈 탭)', () async {
      final (f, _) = await withTwo();
      await f.dispatch(ActionId.navHistory);
      await f.dispatch(ActionId.historyOpen, 'a');
      await f.dispatch(ActionId.navHome);
      expect(f.screen, ScreenId.h);
      expect(f.historyItems, isEmpty);
      expect(f.openedEntry, isNull);
    });

    test('기록 화면에서 열리는 버튼: 열기·지우기·공유 + 하단 탭 + 뒤로 (3-9)', () async {
      final f = _flow();
      await f.dispatch(ActionId.navHistory);
      expect(f.allowed, {
        ActionId.historyOpen,
        ActionId.historyDelete,
        ActionId.sharePrepare,
        ActionId.navHome,
        ActionId.navHistory,
        ActionId.navSettings,
        ActionId.navBack,
      });
    });
  });

  // 시스템설계 3-9 SETTINGS, 일정_현실검토 3-2 [제안] "권한 상태와 맵 revision 두 줄" (협업규격 4.2 5번)
  group('설정 화면 (SETTINGS)', () {
    test('설정 탭 → SETTINGS, 기능 맵 revision을 읽어 둔다', () async {
      final f = testFlow(guidance: _OneActionRepo()); // revision 't'
      await f.dispatch(ActionId.navSettings);
      expect(f.screen, ScreenId.settings);
      expect(f.mapRevision, 't');
    });

    test('권한 관리 → 기기 설정을 열고 설정 화면에 머문다 (권한을 요청하지 않는다)', () async {
      final cleanup = _RecordingCleanup();
      final f = testFlow(cleanup: cleanup);
      await f.dispatch(ActionId.navSettings);
      await f.dispatch(ActionId.settingsOpenPermission);
      expect(cleanup.settingsOpened, 1);
      expect(f.screen, ScreenId.settings);
    });

    test('기록 ↔ 설정 탭을 오가도 기록은 새로 읽는다', () async {
      final history = InMemoryHistoryRepository();
      final f = testFlow(history: history);
      await f.dispatch(ActionId.navSettings);
      await f.dispatch(ActionId.navHistory);
      expect(f.screen, ScreenId.history);
      expect(f.historyItems, isEmpty);

      await history.save(
        HistoryEntry(
          id: 'a',
          actionId: 'chat.send',
          actionTitle: '메시지 보내기',
          stepInstructions: const ['보내기를 누르세요'],
          input: InputKind.gallery,
          createdAt: DateTime(2026, 11, 20),
        ),
      );
      await f.dispatch(ActionId.navSettings);
      await f.dispatch(ActionId.navHistory);
      expect(f.historyItems.map((e) => e.id), ['a'], reason: '설정에 다녀오면 다시 읽음');
    });

    test('뒤로 → 홈, 떠나면 revision을 비운다', () async {
      final f = _flow();
      await f.dispatch(ActionId.navSettings);
      await f.dispatch(ActionId.navBack);
      expect(f.screen, ScreenId.h);
      expect(f.mapRevision, isNull);
    });

    test('설정 화면에서 열리는 버튼: 권한 설정·동기화 + 하단 탭 + 뒤로 (3-9)', () async {
      final f = _flow();
      await f.dispatch(ActionId.navSettings);
      expect(f.allowed, {
        ActionId.settingsOpenPermission,
        ActionId.syncToggle, // 표에는 있고 처리는 '준비 중' (일정_현실검토 3-2: 동기화 동의는 뺀다)
        ActionId.navHome,
        ActionId.navHistory,
        ActionId.navSettings,
        ActionId.navBack,
      });
    });
  });

  // 협업규격 4.2 5번 "모든 버튼 ID에 핸들러".
  // 빠진 갈래는 컴파일러가 잡는다(handle의 switch에 default 없음). 시험은 '준비 중' 목록이 실제 처리와 같은지를 본다.
  group('버튼 등록부', () {
    test('준비 중 목록은 정한 9개뿐 — 기능을 만들면 여기서도 지운다', () {
      expect(GuideFlow.notReady, {
        ActionId.sharePrepare,
        ActionId.shareConfirm,
        ActionId.shareSend,
        ActionId.syncToggle,
        ActionId.mapCheck,
        ActionId.overlaySetup,
        ActionId.overlayStart,
        ActionId.overlayStop,
        ActionId.overlayRescan,
      });
    });

    test('28개 모두: 준비 중 목록에 있는 것만 "준비 중" 문구가 나온다', () async {
      // 관문을 거치지 않는 handle로 누른다 → 홈에서 못 누르는 버튼(공유·기록 열기 등)도 확인된다.
      // 진짜 기능을 넣고 목록에서 안 빼거나, 목록에서 빼고 진짜 기능을 안 넣으면 여기서 실패한다.
      for (final id in ActionId.values) {
        final f = testFlow(); // 버튼마다 새 흐름 (앞 버튼이 상태를 바꾸지 않게)
        await f.handle(id);
        expect(
          f.notice == GuideFlow.notReadyNotice,
          GuideFlow.notReady.contains(id),
          reason: '$id',
        );
      }
    });

    test('화면에서 준비 중 버튼을 누르면 화면은 그대로, 문구만 나온다', () async {
      final f = _flow();
      // 홈의 "화면 실시간 스캔" (관문을 거치는 실제 길, N01은 일정 제외)
      await f.dispatch(ActionId.overlaySetup);
      expect(f.screen, ScreenId.h);
      expect(f.notice, GuideFlow.notReadyNotice);
    });
  });

  test(
    '갤러리 권한 거부 → 권한 안내 화면 DENY(PERMISSION_DENIED), 다른 이미지를 고르면 앞 복사본을 지운다',
    () async {
      final denied = testFlow(
        gallery: FakeGalleryInput(
          access: PickStatus.permissionDenied,
          loadThumbnail: noThumbnail,
        ),
      );
      await denied.dispatch(ActionId.captureGallery);
      // 협업규격 3.4: 권한 거부는 오류 화면(E)이 아니라 권한 안내 화면(DENY)
      expect(denied.screen, ScreenId.deny);
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

  // 협업규격 3.4 결과 → 화면 표 (4.2 4번 끝난 기준: 취소·거부·읽기 실패가 각각 맞는 화면으로)
  group('입력 결과 → 화면 (갤러리 "사용")', () {
    Future<GuideFlow> useWith(PickStatus status) async {
      final f = testFlow(
        gallery: FakeGalleryInput(
          useStatus: status,
          loadThumbnail: noThumbnail,
        ),
      );
      await f.dispatch(ActionId.captureGallery); // H → G
      await f.dispatch(ActionId.capturePick, SampleImage.settings.id); // → GS
      await f.dispatch(ActionId.captureConfirm); // use()
      return f;
    }

    test('취소 → 그 자리(GS) 유지, 오류 없음', () async {
      final f = await useWith(PickStatus.cancelled);
      expect(f.screen, ScreenId.gs);
      expect(f.error, isNull);
      expect(f.picked, isNull);
    });

    test('권한 거부 → DENY, 거부된 입력 방식 = 갤러리', () async {
      final f = await useWith(PickStatus.permissionDenied);
      expect(f.screen, ScreenId.deny);
      expect(f.state, FlowState.denied);
      expect(f.error, ErrorCode.permissionDenied);
      expect(f.deniedInput, InputKind.gallery);
    });

    test('읽기 실패 → E(IMAGE_READ_FAILED)', () async {
      final f = await useWith(PickStatus.readFailed);
      expect(f.screen, ScreenId.e);
      expect(f.error, ErrorCode.imageReadFailed);
      expect(f.deniedInput, isNull);
    });

    test('홈으로 가면 거부 기록을 지운다', () async {
      final f = await useWith(PickStatus.permissionDenied);
      await f.dispatch(ActionId.navBack); // DENY의 뒤로 → 홈 (_back 기본 갈래)
      expect(f.screen, ScreenId.h);
      expect(f.deniedInput, isNull);
    });
  });

  // 카메라 흐름 (시스템설계 3-0·3-3, 협업규격 3.4, 4.2 4번)
  group('카메라 흐름', () {
    test('H → CP → 촬영 → CR → CA → RC, 입력 방식 = 카메라', () async {
      final f = testFlow();
      await f.dispatch(ActionId.captureCamera); // 홈에서 처음: 권한 설명부터
      expect(f.screen, ScreenId.cp);
      expect(f.input, InputKind.camera);

      await f.dispatch(ActionId.captureCamera); // CP에서: 기기 카메라
      expect(f.screen, ScreenId.cr);
      expect(f.state, FlowState.picked);
      expect(f.picked!.input, InputKind.camera);

      await f.dispatch(ActionId.analyzeRun);
      expect(f.screen, ScreenId.rc, reason: '카메라 세션의 결과 장면');
      expect(f.availableActions, isNotEmpty);
    });

    Future<GuideFlow> shootWith(PickStatus status) async {
      final f = testFlow(camera: FakeCameraInput(status: status));
      await f.dispatch(ActionId.captureCamera); // → CP
      await f.dispatch(ActionId.captureCamera); // 촬영
      return f;
    }

    test('촬영 취소 → CP 그대로', () async {
      final f = await shootWith(PickStatus.cancelled);
      expect(f.screen, ScreenId.cp);
      expect(f.picked, isNull);
    });

    test('카메라 권한 거부 → DENY, 거부된 입력 방식 = 카메라', () async {
      final f = await shootWith(PickStatus.permissionDenied);
      expect(f.screen, ScreenId.deny);
      expect(f.deniedInput, InputKind.camera);
    });

    test('읽기 실패 → E(IMAGE_READ_FAILED)', () async {
      final f = await shootWith(PickStatus.readFailed);
      expect(f.screen, ScreenId.e);
      expect(f.error, ErrorCode.imageReadFailed);
    });

    test('분석 취소 → CR, 결과에서 뒤로 → CR, CR에서 뒤로 → CP', () async {
      final f = testFlow(
        analyzer: FakeAnalyzer(delay: const Duration(milliseconds: 30)),
      );
      await f.dispatch(ActionId.captureCamera);
      await f.dispatch(ActionId.captureCamera); // → CR
      final running = f.dispatch(ActionId.analyzeRun);
      expect(f.screen, ScreenId.ca);
      await f.dispatch(ActionId.analyzeCancel);
      expect(f.screen, ScreenId.cr);
      await running;

      await f.dispatch(ActionId.analyzeRun); // → RC
      expect(f.screen, ScreenId.rc);
      await f.dispatch(ActionId.navBack);
      expect(f.screen, ScreenId.cr);
      await f.dispatch(ActionId.navBack);
      expect(f.screen, ScreenId.cp);
    });

    test('CR에서 다시 찍기 → CP를 거치지 않고 바로 촬영, 앞 사진 복사본을 지운다', () async {
      final files = _RecordingFiles();
      final camera = FakeCameraInput(files: files);
      final f = testFlow(files: files, camera: camera);
      await f.dispatch(ActionId.captureCamera);
      await f.dispatch(ActionId.captureCamera); // 첫 사진
      final first = f.picked!.path;

      await f.dispatch(ActionId.captureRetake);
      expect(f.screen, ScreenId.cr);
      expect(f.picked!.path, isNot(first));
      expect(files.released, [first], reason: '협업규격 3.4: 다시 고를 때 삭제');
    });

    test('다시 찍기를 취소하면 앞 사진이 남고 CR에 머문다', () async {
      final files = _RecordingFiles();
      final camera = FakeCameraInput(files: files);
      final f = testFlow(files: files, camera: camera);
      await f.dispatch(ActionId.captureCamera);
      await f.dispatch(ActionId.captureCamera);
      final first = f.picked!.path;

      camera.status = PickStatus.cancelled;
      await f.dispatch(ActionId.captureRetake);
      expect(f.screen, ScreenId.cr);
      expect(f.picked!.path, first);
      expect(files.released, isEmpty);
    });
  });

  // 사진을 가져오는 중에는 모든 버튼 잠금 (11/14 점검에서 재현한 연타 문제)
  group('연타 차단', () {
    test('CP에서 촬영 버튼을 두 번 → 카메라는 한 번만, 오류 화면으로 가지 않는다', () async {
      final cam = _SlowCamera();
      final f = testFlow(camera: cam);
      await f.dispatch(ActionId.captureCamera); // → CP
      final seen = <ScreenId>[];
      f.addListener(() => seen.add(f.screen));

      final first = f.dispatch(ActionId.captureCamera);
      expect(f.capturing, isTrue);
      expect(f.allowed, isEmpty, reason: '가져오는 중에는 뒤로도 잠금');
      final second = f.dispatch(ActionId.captureCamera); // 연타
      await Future.wait([first, second]);

      expect(cam.calls, 1);
      expect(seen, isNot(contains(ScreenId.e)));
      expect(f.screen, ScreenId.cr);
      expect(f.capturing, isFalse, reason: '끝나면 잠금이 풀린다');
    });

    test('갤러리 "선택한 이미지 사용"을 두 번 → 한 번만 가져온다 (복사본이 하나 더 남지 않음)', () async {
      final gallery = _SlowGallery();
      final f = testFlow(gallery: gallery);
      await f.dispatch(ActionId.captureGallery);
      await f.dispatch(ActionId.capturePick, SampleImage.settings.id);

      final first = f.dispatch(ActionId.captureConfirm);
      final second = f.dispatch(ActionId.captureConfirm); // 연타
      await Future.wait([first, second]);

      expect(gallery.useCalls, 1);
      expect(f.screen, ScreenId.gr);
    });

    test('실패로 끝나도 잠금이 풀린다', () async {
      final f = testFlow(
        camera: FakeCameraInput(status: PickStatus.permissionDenied),
      );
      await f.dispatch(ActionId.captureCamera);
      await f.dispatch(ActionId.captureCamera); // → DENY
      expect(f.screen, ScreenId.deny);
      expect(f.capturing, isFalse);
      expect(f.allows(ActionId.captureGallery), isTrue);
    });
  });

  // 권한 안내 화면 DENY의 버튼 (시스템설계 3-9, 협업규격 3.5)
  group('권한 안내 DENY', () {
    test('설정 열기 → 기기 설정을 열고 DENY에 머문다', () async {
      final cleanup = _RecordingCleanup();
      final f = testFlow(
        cleanup: cleanup,
        camera: FakeCameraInput(status: PickStatus.permissionDenied),
      );
      await f.dispatch(ActionId.captureCamera);
      await f.dispatch(ActionId.captureCamera); // → DENY
      await f.dispatch(ActionId.settingsOpenPermission);
      expect(cleanup.settingsOpened, 1);
      expect(f.screen, ScreenId.deny);
    });

    test('카메라 거부 → "갤러리에서 선택"(captureGallery) → 갤러리 목록', () async {
      final f = testFlow(
        camera: FakeCameraInput(status: PickStatus.permissionDenied),
      );
      await f.dispatch(ActionId.captureCamera);
      await f.dispatch(ActionId.captureCamera); // → DENY
      await f.dispatch(ActionId.captureGallery);
      expect(f.screen, ScreenId.g);
      expect(f.input, InputKind.gallery);
    });

    test('갤러리 거부 → 설정에서 허용 → "다시 시도"(captureGallery) → 갤러리 목록', () async {
      final gallery = FakeGalleryInput(
        access: PickStatus.permissionDenied,
        loadThumbnail: noThumbnail,
      );
      final f = testFlow(gallery: gallery);
      await f.dispatch(ActionId.captureGallery);
      expect(f.screen, ScreenId.deny);

      gallery.access = PickStatus.ok; // 사용자가 기기 설정에서 허용하고 돌아옴
      await f.dispatch(ActionId.captureGallery);
      expect(f.screen, ScreenId.g);
    });
  });

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

  test('진행 칸: 입력 1 → 선택 3, 분석에서 실패하면 오류 화면은 2에 멈춘다 (4-1, 3-9)', () async {
    final f = _flow();
    expect(f.progress, isNull, reason: '홈은 진행 표시 없음');
    await _pickSample(f, SampleImage.settings);
    expect(f.progress, 1);
    await f.dispatch(ActionId.analyzeRun);
    expect(f.progress, 3);

    final failed = await _toResult(
      SampleImage.settings,
      FakeAnalyzer(delay: Duration.zero, failWith: ErrorCode.analysisFailed),
    );
    expect(failed.screen, ScreenId.e);
    expect(failed.progress, 2, reason: '분석에서 실패');

    await failed.dispatch(ActionId.navHome);
    expect(failed.progress, isNull, reason: '홈으로 가면 실패 단계도 지운다');
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
  var settingsOpened = 0;
  @override
  Future<void> clearLeftovers() async => cleared++;
  @override
  Future<void> openAppSettings() async => settingsOpened++;
  @override
  Future<void> release(PickedImage image) async {}
}
