// 생성자 인자 이름은 공개(analyzer, guidance …), 필드는 비공개로 두려고 initializing formal을 쓰지 않는다.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:screen_guide/app/stage.dart';
import 'package:screen_guide/app/stage_table.dart';
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

  /// 공유 전 확인(P)에서 "확인했어요"를 눌렀는가. 꺼져 있으면 `shareSend`를 잠근다.
  /// 화면이 바꿀 수 없게 비공개로 두고 읽기만 열어 둔다 (협업규격 3.6: 세션 값은 흐름이 가진다).
  /// 공유 단계에 들어올 때 끄는 곳은 [_onEnter]. 켜는 곳(shareConfirm)은 공유 화면을 만들 때(협업규격 4.2 5번) 넣는다.
  bool get shareConfirmed => _shareConfirmed;
  bool _shareConfirmed = false;

  /// 권한이 거부된 입력 방식 (협업규격 3.4 "거부된 입력 방식을 세션에 기록", 3.6 세션 값).
  /// 권한 안내 화면(DENY)이 이 값을 보고 "설정 열기"와 "다른 방법으로 대신하기"를 고른다.
  InputKind? get deniedInput => _deniedInput;
  InputKind? _deniedInput;

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

  // ───────────── 관문: 단계 설정표를 본다 (시스템설계_최종 3-1, 6-2 ①) ─────────────

  /// 표(고정)가 정한 버튼에서, 흐름의 상태에 따라 더 잠근다.
  /// 표 = "이 장면에서 원래 누를 수 있는 것", 여기 = "지금 이 순간 막아야 하는 것".
  Set<ActionId> get allowed {
    final s = {...StageTable.always, ...StageTable.allowedOn(screen)};
    // 대상을 찾는 중에는 단계 버튼 잠금 (3-6, 중복 실행 차단)
    if (locating) s.removeAll(_stepActions);
    // P에서 확인하기 전에는 보낼 수 없다 (기능별_검토_결론 5장 관문, 필수)
    if (!_shareConfirmed) s.remove(ActionId.shareSend);
    return s;
  }

  static const _stepActions = {
    ActionId.guideNext,
    ActionId.guidePrev,
    ActionId.guideMismatch,
  };

  bool allows(ActionId id) => allowed.contains(id);

  // ───────────── 화면 틀: 진행 표시 (시스템설계_최종 4-1) ─────────────

  /// 진행 표시 5칸 중 지금 칸 (1 입력 ~ 5 완료). 진행 표시가 없는 화면이면 null.
  /// 복구 화면은 실패한 단계의 칸에 멈춘다 (3-9).
  int? get progress {
    final stage = screen.stage == Stage.recover ? _failedStage : screen.stage;
    if (stage == null) return null;
    return StageTable.ruleFor(stage).progress;
  }

  /// 마지막으로 실패한 단계. 복구 단계에 들어올 때(_onEnter) 정하고 [_reset]이 지운다.
  /// 오류 화면끼리(E ↔ DENY)는 같은 복구 단계라 _onEnter가 돌지 않으므로 처음 실패한 단계가 남는다.
  Stage? _failedStage;

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
    if (access != PickStatus.ok) {
      return _onPickFailed(access, InputKind.gallery);
    }
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
    if (!img.ok) return _onPickFailed(img.status, InputKind.gallery);
    picked = img;
    _go(ScreenId.gr, FlowState.picked);
  }

  /// 입력 포트의 실패 결과 → 화면 (협업규격 3.4 표). 갤러리·카메라가 같이 쓴다.
  ///
  /// | 결과 | 화면 |
  /// |---|---|
  /// | cancelled | 그 자리 유지 |
  /// | permissionDenied | DENY (`PERMISSION_DENIED`), 거부된 입력 방식 기록 |
  /// | readFailed | E (`IMAGE_READ_FAILED`) |
  /// | ok인데 파일 경로 없음 | 읽기 실패로 본다 (쓸 수 있는 이미지가 없다) |
  void _onPickFailed(PickStatus status, InputKind kind) {
    switch (status) {
      case PickStatus.cancelled:
        return;
      case PickStatus.permissionDenied:
        _deniedInput = kind;
        error = ErrorCode.permissionDenied;
        _go(ScreenId.deny, FlowState.denied);
      case PickStatus.readFailed:
      case PickStatus.ok:
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

  /// 분석 취소 → 확인 장면(GR)으로. 요청 번호 버리기·타이머 정지는 _onExit(analyze)가 한다.
  void _cancel() {
    _go(ScreenId.gr, FlowState.picked);
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
    _go(ScreenId.e, FlowState.error); // 실패한 단계 기억은 _onEnter(recover)가 한다
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
    _shareConfirmed = false;
    _failedStage = null;
    _deniedInput = null;
    _go(ScreenId.h, FlowState.idle);
  }

  /// 화면을 바꾼다. 단계까지 바뀌면 나가는 단계를 정리하고 들어가는 단계를 준비한다 (6-2, 6-4 6번).
  /// 같은 단계 안의 이동(G → GS, D1 → D2)에서는 아무것도 하지 않는다.
  void _go(ScreenId s, FlowState st) {
    final from = screen.stage;
    final to = s.stage;
    screen = s;
    state = st;
    if (from != to) {
      _onExit(from);
      _onEnter(to, from: from);
    }
  }

  // ───────────── 단계에 들어갈 때·나갈 때 (시스템설계_최종 3-1 "들어갈 때 준비 / 나갈 때 정리") ─────────────
  //
  // 여기에는 바로 끝나는 일(값 바꾸기, 타이머 멈추기)만 둔다.
  // 파일 삭제처럼 기다려야 하는 일은 _go가 기다릴 수 없어서 _reset·_retake·_confirm에 둔다 (협업규격 3.4 호출 시점).
  // switch에 default가 없어 단계가 새로 생기면 컴파일 오류로 빠진 갈래를 알려 준다.

  void _onExit(Stage stage) {
    switch (stage) {
      case Stage.analyze:
        // 3-4 나갈 때: 타이머 정지. 요청 번호도 버려서 늦게 온 응답은 무시된다 (계약 v1 결정 3).
        _pendingId = null;
        _slowTimer?.cancel();
        slow = false;
      case Stage.ready:
      case Stage.waiting:
      case Stage.input:
      case Stage.choose:
      case Stage.guide:
      case Stage.finish:
      case Stage.share:
      case Stage.recover:
      case Stage.records:
      case Stage.overlay:
        break; // 아직 할 일 없음
    }
  }

  void _onEnter(Stage stage, {required Stage from}) {
    switch (stage) {
      case Stage.recover:
        // 3-9: 어디서 왔는지 기억한다 → 진행 칸을 그 단계에 멈춘다.
        _failedStage = from;
      case Stage.share:
        // 기능별_검토_결론 5장: 공유 단계에 들어올 때마다 "확인함"을 지운다 → P를 다시 거쳐야 보낼 수 있다.
        _shareConfirmed = false;
      case Stage.ready:
      case Stage.waiting: // 세션 비우기·복사본 삭제는 _reset이 한다 (기다려야 하는 일)
      case Stage.input:
      case Stage.analyze:
      case Stage.choose:
      case Stage.guide:
      case Stage.finish:
      case Stage.records:
      case Stage.overlay:
        break; // 아직 할 일 없음
    }
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
