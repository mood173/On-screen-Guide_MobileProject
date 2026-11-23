import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/app/home_screen.dart';
import 'package:screen_guide/features/analyze/ui/analyzing_screen.dart';
import 'package:screen_guide/features/capture/ui/camera_permission_screen.dart';
import 'package:screen_guide/features/capture/ui/gallery_screen.dart';
import 'package:screen_guide/features/capture/ui/review_screen.dart';
import 'package:screen_guide/features/guide/ui/done_screen.dart';
import 'package:screen_guide/features/guide/ui/error_screen.dart';
import 'package:screen_guide/features/guide/ui/guide_step_screen.dart';
import 'package:screen_guide/features/guide/ui/result_screen.dart';
import 'package:screen_guide/features/history/ui/history_screen.dart';
import 'package:screen_guide/features/privacy/ui/privacy_check_screen.dart';
import 'package:screen_guide/features/settings/ui/deny_screen.dart';
import 'package:screen_guide/features/settings/ui/settings_screen.dart';
import 'package:screen_guide/features/share/ui/share_screen.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';
import 'package:screen_guide/shared/theme/app_theme.dart';

class ScreenGuideApp extends StatelessWidget {
  const ScreenGuideApp({super.key, required this.flow});

  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '화면길잡이',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: FlowShell(flow: flow),
    );
  }
}

/// 흐름 관리자의 현재 화면 ID를 보고 화면을 고른다. 화면 전환은 상태가 정하고, 위젯은 그리기만 한다.
class FlowShell extends StatefulWidget {
  const FlowShell({super.key, required this.flow});
  final GuideFlow flow;

  @override
  State<FlowShell> createState() => _FlowShellState();
}

class _FlowShellState extends State<FlowShell> {
  GuideFlow get flow => widget.flow;

  @override
  void initState() {
    super.initState();
    flow.addListener(_showNotice);
  }

  @override
  void dispose() {
    flow.removeListener(_showNotice);
    super.dispose();
  }

  void _showNotice() {
    final msg = flow.notice;
    if (msg == null) return;
    flow.clearNotice();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
  }

  Widget _screen() => switch (flow.screen) {
    ScreenId.h => HomeScreen(flow: flow),
    ScreenId.cp => CameraPermissionScreen(flow: flow),
    ScreenId.g || ScreenId.gs => GalleryScreen(flow: flow),
    // 갤러리·카메라가 같은 장면이면 위젯 하나 (시스템설계 3-0).
    ScreenId.gr || ScreenId.cr => ReviewScreen(flow: flow),
    ScreenId.ga || ScreenId.ca => AnalyzingScreen(flow: flow),
    ScreenId.rg || ScreenId.rc => ResultScreen(flow: flow),
    ScreenId.d1 ||
    ScreenId.d2 ||
    ScreenId.d3 ||
    ScreenId.d4 ||
    ScreenId.d5 => GuideStepScreen(flow: flow),
    ScreenId.done => DoneScreen(flow: flow),
    ScreenId.e => ErrorScreen(flow: flow),
    ScreenId.deny => DenyScreen(flow: flow),
    ScreenId.history => HistoryScreen(flow: flow),
    ScreenId.settings => SettingsScreen(flow: flow),
    // P는 흐름을 모르게 목록과 버튼 동작만 넘긴다 (검토 결론 5장 필수)
    ScreenId.p => PrivacyCheckScreen(
      candidates: flow.shareDraft?.candidates ?? const [],
      onConfirm: flow.allows(ActionId.shareConfirm)
          ? () => flow.dispatch(ActionId.shareConfirm)
          : null,
      onBack: () => flow.dispatch(ActionId.navBack),
    ),
    // SHARE도 보낼 글과 버튼 동작만 넘긴다 (미리보기 = 보낼 글, flow.shareText)
    ScreenId.share => ShareScreen(
      text: flow.shareText ?? '',
      onSend: flow.allows(ActionId.shareSend)
          ? () => flow.dispatch(ActionId.shareSend)
          : null,
      onBack: flow.allows(ActionId.navBack)
          ? () => flow.dispatch(ActionId.navBack)
          : null,
    ),
    // 기기 기본 카메라가 화면을 대신하는 동안의 앱 장면 (C). 도달하면 안내만 그린다.
    ScreenId.c => const _NotBuilt('카메라 촬영 화면은 기기 카메라가 대신해요'),
    // 실시간 안내(오버레이)는 일정 제외. 라우팅을 숨기지 않고 명시한다 (E-11).
    ScreenId.lp ||
    ScreenId.l ||
    ScreenId.lo ||
    ScreenId.lt ||
    ScreenId.lx ||
    ScreenId.lg1 ||
    ScreenId.lg2 ||
    ScreenId.lg3 ||
    ScreenId.lg4 ||
    ScreenId.lg5 => const _NotBuilt('실시간 안내는 아직 준비 중이에요'),
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: flow,
      builder: (context, _) => PopScope(
        // 홈에서는 시스템 뒤로가기로 앱을 닫고, 그 외에는 흐름의 navBack으로 처리한다.
        canPop: flow.screen == ScreenId.h,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) flow.dispatch(ActionId.navBack);
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(
              flow.screen == ScreenId.gs ? ScreenId.g : flow.screen,
            ),
            child: _screen(),
          ),
        ),
      ),
    );
  }
}

/// 아직 화면이 없는 장면의 자리. 조용히 홈으로 폴백하지 않고 무엇이 없는지 보여 준다 (E-11).
class _NotBuilt extends StatelessWidget {
  const _NotBuilt(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    ),
  );
}
