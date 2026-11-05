// 생성자 인자 이름은 공개(analyzer, files), 필드는 비공개로 두려고 initializing formal을 쓰지 않는다.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../contract/analysis.dart';
import '../core/action_id.dart';
import '../core/error_code.dart';
import '../core/flow_state.dart';
import '../core/screen_id.dart';
import '../data/demo_guidance.dart';
import '../data/image_files.dart';
import '../data/sample_images.dart';
import '../domain/screen_analyzer.dart';

/// 흐름 관리자 (설계 6.1 4층 런타임·관문 + 5층 기능).
///
/// 화면(셀)은 [dispatch]로 [ActionId]만 올린다. 여기서 Gate([allowed])를 통과한 행동만 처리하고,
/// 결과를 상태로 바꿔 [notifyListeners]로 알린다. 화면은 상태를 보고 다시 그리기만 한다.
class GuideFlow extends ChangeNotifier {
  GuideFlow({
    required ScreenAnalyzer analyzer,
    ImageFiles files = const AssetPathImageFiles(),
    this.slowAfter = const Duration(seconds: 3),
  }) : _analyzer = analyzer,
       _files = files;

  final ScreenAnalyzer _analyzer;
  final ImageFiles _files;

  /// 분석 요청에 넣는 파일 경로 (앱 캐시에 만든 복사본)
  String? _imagePath;

  /// 이 시간이 지나도 분석이 끝나지 않으면 [slow]를 켠다 (계약 v1 결정 3: 오류로 끊지 않음).
  final Duration slowAfter;

  // ───────────── 상태 (화면이 읽는 값) ─────────────
  ScreenId screen = ScreenId.h;
  FlowState state = FlowState.idle;

  /// G·GS에서 고른 이미지
  SampleImage? picked;

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

  List<GuideAction> get availableActions =>
      DemoGuidance.forScreen(result?.screenId);
  int get totalSteps => action?.steps.length ?? 0;
  GuideStep? get currentStep => action?.steps[step];

  // ───────────── Gate: 화면별로 허용하는 행동 ─────────────
  static const _always = {ActionId.navBack, ActionId.navHome};
  static const _gate = <ScreenId, Set<ActionId>>{
    ScreenId.h: {
      ActionId.captureGallery,
      ActionId.captureCamera,
      ActionId.overlaySetup,
      ActionId.historyOpen,
      ActionId.settingsOpenPermission,
    },
    ScreenId.g: {ActionId.captureGallery},
    ScreenId.gs: {ActionId.captureGallery, ActionId.captureRetake},
    ScreenId.gr: {ActionId.analyzeRun, ActionId.captureRetake},
    ScreenId.ga: {ActionId.analyzeCancel},
    ScreenId.rg: {
      ActionId.guideStart,
      ActionId.sharePrepare,
      ActionId.historySave,
    },
    ScreenId.d1: _stepActions,
    ScreenId.d2: _stepActions,
    ScreenId.d3: _stepActions,
    ScreenId.d4: _stepActions,
    ScreenId.d5: _stepActions,
    ScreenId.done: {ActionId.historySave, ActionId.sharePrepare},
    ScreenId.e: {
      ActionId.captureRetake,
      ActionId.captureCamera,
      ActionId.overlayRescan,
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
        await _gallery(arg);
      case ActionId.captureRetake:
        _go(ScreenId.g, FlowState.idle);
        picked = null;
        _releaseFile();
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
        _back();
      case ActionId.navHome:
        _reset();
      default:
        notice = '이 기능은 아직 준비 중이에요';
    }
    notifyListeners();
  }

  void clearNotice() => notice = null;

  // ───────────── 기능 (핸들러) ─────────────
  Future<void> _gallery(Object? arg) async {
    if (screen == ScreenId.h) {
      _go(ScreenId.g, FlowState.idle);
    } else if (arg is SampleImage) {
      picked = arg; // G·GS에서 이미지를 누름 → 선택 상태
      _go(ScreenId.gs, FlowState.idle);
    } else if (screen == ScreenId.gs && picked != null) {
      // "선택한 이미지 사용": Kotlin이 열 수 있는 파일 경로를 준비한다
      _releaseFile();
      _imagePath = await _files.prepare(picked!);
      _go(ScreenId.gr, FlowState.picked);
    }
  }

  void _releaseFile() {
    final p = _imagePath;
    _imagePath = null;
    if (p != null) _files.release(p);
  }

  AnalyzeRequest _request({TargetRequest? target}) => AnalyzeRequest(
    requestId: 'r${++_seq}',
    imagePath: _imagePath ?? picked!.asset,
    guidance: DemoGuidance.fragment,
    target: target,
  );

  Future<AnalysisResult?> _run(AnalyzeRequest req) async {
    _pendingId = req.requestId;
    slow = false;
    _slowTimer?.cancel();
    _slowTimer = Timer(slowAfter, () {
      if (_pendingId == req.requestId) {
        slow = true;
        notifyListeners();
      }
    });
    final r = await _analyzer.analyze(req);
    _slowTimer?.cancel();
    if (_pendingId != req.requestId) return null; // 취소됐거나 더 새 요청이 있음 → 응답 버림
    _pendingId = null;
    slow = false;
    return r;
  }

  Future<void> _analyzeFirst() async {
    if (picked == null) return;
    _go(ScreenId.ga, FlowState.analyzing);
    notifyListeners();
    final r = await _run(_request());
    if (r == null) return;
    if (!r.ok) return _fail(r.errorCode ?? ErrorCode.analysisFailed);
    if (r.screenId == null) return _fail(ErrorCode.unknownScreen);
    result = r;
    _go(ScreenId.rg, FlowState.identified);
  }

  void _cancel() {
    _pendingId = null;
    _slowTimer?.cancel();
    slow = false;
    _go(ScreenId.gr, FlowState.picked); // 분석 취소 → 이전 화면 유지
  }

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
    final r = await _run(
      _request(
        target: TargetRequest(
          actionId: action!.actionId,
          stepIndex: step,
          selector: s.selector,
        ),
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

  void _fail(ErrorCode code) {
    error = code;
    locating = false;
    _go(ScreenId.e, FlowState.error);
  }

  void _back() {
    switch (screen) {
      case ScreenId.g:
        _reset();
      case ScreenId.gs:
        picked = null;
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
          _locate();
        } else {
          _pendingId = null;
          locating = false;
          _go(ScreenId.rg, FlowState.identified);
        }
      default:
        _reset();
    }
  }

  void _reset() {
    _pendingId = null;
    _slowTimer?.cancel();
    picked = null;
    _releaseFile(); // 앱이 만든 복사본 정리
    result = null;
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
