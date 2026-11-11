// 생성자 인자 이름은 공개(analyzer, guidance …), 필드는 비공개로 두려고 initializing formal을 쓰지 않는다.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:screen_guide/features/analyze/domain/screen_analyzer.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/guidance_map/domain/guidance.dart';
import 'package:screen_guide/features/guidance_map/domain/map_updater.dart';
import 'package:screen_guide/features/history/domain/history.dart';
import 'package:screen_guide/features/share/domain/sharer.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/contracts/analysis.dart';
import 'package:screen_guide/shared/contracts/error_code.dart';
import 'package:screen_guide/shared/contracts/flow_state.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';

/// 흐름 입구 (시스템설계_최종 6-2).
///
/// 화면(셀)은 [dispatch]로 [ActionId]만 올린다. 여기서 관문([allowed])을 통과한 행동만 처리하고,
/// 결과를 상태로 바꿔 [notifyListeners]로 알린다. 화면은 상태를 보고 다시 그리기만 한다.
///
/// 흐름은 포트(인터페이스)만 안다. 구현은 app/bootstrap.dart와 시험 코드가 생성자로 넘긴다 (협업규격_최종 2장).
class GuideFlow extends ChangeNotifier {
  GuideFlow({
    required ScreenAnalyzer analyzer,
    required GuidanceRepository guidance,
    required HistoryRepository history,
    required GalleryInput galleryInput,
    required CameraInput cameraInput,
    required InputCleanup inputCleanup,
    required Sharer sharer,
    required MapUpdater mapUpdater,
    this.slowAfter = const Duration(seconds: 3),
    DateTime Function() now = DateTime.now,
  }) : _analyzer = analyzer,
       _guidance = guidance,
       _history = history,
       _gallery = galleryInput,
       _camera = cameraInput,
       _cleanup = inputCleanup,
       _sharer = sharer,
       _mapUpdater = mapUpdater,
       _now = now;

  // ── 연결 지점 (포트) ──
  final ScreenAnalyzer _analyzer; // 강민준 (Kotlin 채널)
  final GuidanceRepository _guidance; // 최정혁 (기능 맵)
  final HistoryRepository _history; // 최정혁 (기록)
  final GalleryInput _gallery; // 최정혁 (사진 가져오기)
  // ignore: unused_field
  final CameraInput _camera; // 최정혁 — 카메라 장면(CP)을 만들 때 사용
  final InputCleanup _cleanup; // 최정혁
  // ignore: unused_field
  final Sharer _sharer; // 최정혁 — 공유(P → SHARE)를 만들 때 사용
  final MapUpdater _mapUpdater; // 최정혁

  /// 기록 시각 (시험에서 고정할 수 있게 주입)
  final DateTime Function() _now;

  /// 이 시간이 지나도 분석이 끝나지 않으면 [slow]를 켠다 (계약 v1 결정 3: 오류로 끊지 않음).
  final Duration slowAfter;

  // ───────────── 상태 (화면이 읽는 값) ─────────────
  ScreenId screen = ScreenId.h;
  FlowState state = FlowState.idle;

  /// 이번 세션의 입력 방식 (갤러리·카메라). 복구 화면의 버튼과 기록에 쓴다.
  InputKind? input;

  /// G: 최근 사진 목록
  List<GalleryItem> galleryItems = const [];

  /// GS: 목록에서 고른 칸
  String? selectedId;

  /// 가져온 사진 (앱 복사본). 세션이 끝날 때 [InputCleanup.release]로 지운다.
  PickedImage? picked;

  /// 첫 분석 결과 (RG)
  AnalysisResult? result;

  /// 고른 기능과 현재 단계
  GuideAction? action;
  int step = 0;

  /// 현재 단계에서 찾은 목표 UI. 단계 화면에서 다시 찾는 중이면 null.
  TargetMatch? target;

  /// 단계 화면 안에서 대상을 다시 찾는 중
  bool locating = false;

  ErrorCode? error;

  /// 분석이 [slowAfter]를 넘김 → "조금 더 걸리고 있어요"
  bool slow = false;

  /// 아직 없는 기능을 눌렀을 때 한 번 보여 줄 문구. 화면이 보여 준 뒤 [clearNotice]를 부른다.
  String? notice;

  String? _pendingId;
  int _seq = 0;
  Timer? _slowTimer;

  /// 식별된 화면에서 고를 수 있는 기능 (GuidanceRepository.actionsFor 결과)
  List<GuideAction> availableActions = const [];
  int get totalSteps => action?.steps.length ?? 0;
  GuideStep? get currentStep => action?.steps[step];

  // ───────────── 준비 단계 (앱 시작) ─────────────

  /// 앱 시작 때 한 번. 남은 복사본 청소와 맵 갱신 확인을 시작하고 결과를 기다리지 않는다 (협업규격_최종 3.4).
  void start() {
    unawaited(_cleanup.clearLeftovers());
    unawaited(_mapUpdater.checkForUpdate());
  }

  // ───────────── Gate: 화면별로 허용하는 행동 ─────────────
  static const _always = {ActionId.navBack, ActionId.navHome};
  static const _gate = <ScreenId, Set<ActionId>>{
    // 대기 (시스템설계_최종 3-2)
    ScreenId.h: {
      ActionId.captureGallery,
      ActionId.captureCamera,
      ActionId.overlaySetup,
      ActionId.navHistory,
      ActionId.navSettings,
    },
    ScreenId.g: {ActionId.capturePick},
    ScreenId.gs: {
      ActionId.capturePick,
      ActionId.captureConfirm,
      ActionId.captureRetake,
    },
    ScreenId.gr: {ActionId.analyzeRun, ActionId.captureRetake},
    ScreenId.ga: {ActionId.analyzeCancel},
    // 선택: 저장·공유는 열지 않는다 (기능별_검토_결론 13장 X1)
    ScreenId.rg: {ActionId.guideStart, ActionId.captureRetake},
    ScreenId.d1: _stepActions,
    ScreenId.d2: _stepActions,
    ScreenId.d3: _stepActions,
    ScreenId.d4: _stepActions,
    ScreenId.d5: _stepActions,
    ScreenId.done: {ActionId.historySave, ActionId.sharePrepare},
    // 복구 (시스템설계_최종 3-9). 화면은 세션의 입력 방식에 맞는 버튼만 보여 준다
    ScreenId.e: {
      ActionId.captureRetake,
      ActionId.captureCamera,
      ActionId.captureGallery,
    },
  };
  static const _stepActions = {
    ActionId.guideNext,
    ActionId.guidePrev,
    ActionId.guideMismatch,
  };

  Set<ActionId> get allowed {
    var s = {..._always, ...?_gate[screen]};
    if (locating) {
      s = s.difference(_stepActions); // 다시 찾는 중에는 단계 버튼 잠금 (중복 실행 차단)
    }
    return s;
  }

  bool allows(ActionId id) => allowed.contains(id);

  // ───────────── dispatch ─────────────
  Future<void> dispatch(ActionId id, [Object? arg]) async {
    if (!allows(id)) return;
    switch (id) {
      case ActionId.captureGallery:
        await _openGallery();
      case ActionId.capturePick:
        if (arg is String) _pick(arg);
      case ActionId.captureConfirm:
        await _confirm();
      case ActionId.captureRetake:
        await _retake();
      case ActionId.analyzeRun:
        await _analyzeFirst();
      case ActionId.analyzeCancel:
        _cancel();
      case ActionId.guideStart:
        if (arg is GuideAction) await _startGuide(arg);
      case ActionId.guideNext:
        await _next();
      case ActionId.guidePrev:
        if (step > 0) {
          step--;
          await _locate();
        }
      case ActionId.guideMismatch:
        await _locate(); // 같은 기능 ID를 유지한 채 현재 화면을 다시 분석
      case ActionId.navBack:
        await _back();
      case ActionId.navHome:
        await _reset();
      case ActionId.historySave:
        await _saveHistory();
      default:
        notice = '이 기능은 아직 준비 중이에요';
    }
    notifyListeners();
  }

  void clearNotice() => notice = null;

  // ───────────── 입력 (갤러리) ─────────────
  Future<void> _openGallery() async {
    input = InputKind.gallery;
    final access = await _gallery.requestAccess();
    if (access != PickStatus.ok) return _fail(ErrorCode.permissionDenied);
    galleryItems = await _gallery.recent();
    selectedId = null;
    _go(ScreenId.g, FlowState.idle);
  }

  void _pick(String id) {
    selectedId = id;
    _go(ScreenId.gs, FlowState.idle);
  }

  /// "선택한 이미지 사용": 고른 한 장을 앱 복사본으로 준비한다. 앞 이미지의 복사본은 지운다.
  Future<void> _confirm() async {
    final id = selectedId;
    if (id == null) return;
    await _releasePicked();
    final img = await _gallery.use(id);
    switch (img.status) {
      case PickStatus.ok when img.ok:
        picked = img;
        _go(ScreenId.gr, FlowState.picked);
      case PickStatus.cancelled:
        break; // 그 자리 유지
      case PickStatus.permissionDenied:
        _fail(ErrorCode.permissionDenied);
      default:
        _fail(ErrorCode.imageReadFailed);
    }
  }

  /// 다른 이미지 고르기: 지금 이미지의 복사본을 지우고 목록으로.
  Future<void> _retake() async {
    await _releasePicked();
    selectedId = null;
    result = null;
    error = null;
    if (galleryItems.isEmpty) {
      await _openGallery();
    } else {
      _go(ScreenId.g, FlowState.idle);
    }
  }

  Future<void> _releasePicked() async {
    final p = picked;
    picked = null;
    if (p != null) await _cleanup.release(p);
  }

  // ───────────── 분석 ─────────────

  /// 분석 요청 한 번. 요청 번호를 **맨 먼저** 정해 두어서, 기능 맵을 읽는 중이든 분석 중이든
  /// 취소·새 요청이 생기면 그 뒤의 응답은 버린다 (계약 v1 결정 3: Flutter가 requestId를 버림).
  /// 버린 경우 null.
  Future<AnalysisResult?> _analyze({TargetRequest? target}) async {
    final id = 'r${++_seq}';
    _pendingId = id;
    slow = false;
    _slowTimer?.cancel();
    _slowTimer = Timer(slowAfter, () {
      if (_pendingId == id) {
        slow = true;
        notifyListeners();
      }
    });
    final req = AnalyzeRequest(
      requestId: id,
      imagePath: picked!.path!,
      guidance: await _guidance.fragment(),
      target: target,
    );
    if (_pendingId != id) return null; // 맵을 읽는 사이에 취소됨
    final r = await _analyzer.analyze(req);
    if (_pendingId != id) return null; // 분석 중에 취소됐거나 더 새 요청이 있음
    _slowTimer?.cancel();
    _pendingId = null;
    slow = false;
    return r;
  }

  Future<void> _analyzeFirst() async {
    if (picked?.ok != true) return;
    _go(ScreenId.ga, FlowState.analyzing);
    notifyListeners();
    final r = await _analyze();
    if (r == null) return;
    if (!r.ok) return _fail(r.errorCode ?? ErrorCode.analysisFailed);
    if (r.screenId == null) return _fail(ErrorCode.unknownScreen);
    result = r;
    availableActions = await _guidance.actionsFor(r.screenId!);
    _go(ScreenId.rg, FlowState.identified);
  }

  void _cancel() {
    _pendingId = null;
    _slowTimer?.cancel();
    slow = false;
    _go(ScreenId.gr, FlowState.picked); // 분석 취소 → 이전 화면 유지
  }

  // ───────────── 안내 ─────────────
  Future<void> _startGuide(GuideAction a) async {
    action = a;
    step = 0;
    await _locate();
  }

  /// 현재 단계의 selector로 대상을 찾는다. 찾으면 D(step) 화면, 못 찾으면 E(NO_TARGET).
  Future<void> _locate() async {
    final s = currentStep;
    if (s == null) return;
    _go(_stepScreen(step), FlowState.guiding);
    target = null;
    locating = true;
    notifyListeners();
    final r = await _analyze(
      target: TargetRequest(
        actionId: action!.actionId,
        stepIndex: step,
        selector: s.selector,
      ),
    );
    locating = false;
    if (r == null) return;
    if (!r.ok) return _fail(r.errorCode ?? ErrorCode.analysisFailed);
    if (r.target == null) return _fail(ErrorCode.noTarget);
    target = r.target;
  }

  Future<void> _next() async {
    if (step + 1 < totalSteps) {
      step++;
      await _locate();
    } else {
      _go(ScreenId.done, FlowState.done);
    }
  }

  // ───────────── 마무리 ─────────────

  /// 안내 기록 저장. 이미지·화면에서 읽은 글자·후보 값은 넣지 않는다.
  Future<void> _saveHistory() async {
    final a = action;
    if (a == null) {
      notice = '기능을 골라 안내를 받은 뒤 저장할 수 있어요';
      return;
    }
    final at = _now();
    await _history.save(
      HistoryEntry(
        id: 'h${at.microsecondsSinceEpoch}',
        actionId: a.actionId,
        actionTitle: a.title,
        stepInstructions: [for (final s in a.steps) s.instruction],
        input: picked?.input ?? input ?? InputKind.gallery,
        createdAt: at,
        piiTypes: [
          for (final p in result?.pii ?? const <PiiCandidate>[]) p.type,
        ],
      ),
    );
    notice = '안내 기록에 저장했어요';
  }

  /// HISTORY 화면이 읽는다.
  Future<List<HistoryEntry>> historyList() => _history.list();

  // ───────────── 복구·이동 ─────────────
  void _fail(ErrorCode code) {
    error = code;
    locating = false;
    _go(ScreenId.e, FlowState.error);
  }

  Future<void> _back() async {
    switch (screen) {
      case ScreenId.g:
        await _reset();
      case ScreenId.gs:
        selectedId = null;
        _go(ScreenId.g, FlowState.idle);
      case ScreenId.gr:
        _go(ScreenId.gs, FlowState.idle);
      case ScreenId.ga:
        _cancel();
      case ScreenId.rg:
        _go(ScreenId.gr, FlowState.picked);
      case ScreenId.d1 ||
          ScreenId.d2 ||
          ScreenId.d3 ||
          ScreenId.d4 ||
          ScreenId.d5:
        if (step > 0) {
          step--;
          await _locate();
        } else {
          _pendingId = null;
          locating = false;
          _go(ScreenId.rg, FlowState.identified);
        }
      default:
        await _reset();
    }
  }

  /// 세션 끝: 대기(H)로 돌아가며 앱 복사본을 지운다.
  Future<void> _reset() async {
    _pendingId = null;
    _slowTimer?.cancel();
    await _releasePicked();
    input = null;
    galleryItems = const [];
    selectedId = null;
    result = null;
    availableActions = const [];
    action = null;
    step = 0;
    target = null;
    locating = false;
    error = null;
    slow = false;
    _go(ScreenId.h, FlowState.idle);
  }

  void _go(ScreenId s, FlowState st) {
    screen = s;
    state = st;
  }

  static ScreenId _stepScreen(int i) => const [
    ScreenId.d1,
    ScreenId.d2,
    ScreenId.d3,
    ScreenId.d4,
    ScreenId.d5,
  ][i.clamp(0, 4)];

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }
}
