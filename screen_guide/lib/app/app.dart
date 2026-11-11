import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/app/home_screen.dart';
import 'package:screen_guide/features/analyze/ui/analyzing_screen.dart';
import 'package:screen_guide/features/capture/ui/gallery_screen.dart';
import 'package:screen_guide/features/capture/ui/review_screen.dart';
import 'package:screen_guide/features/guide/ui/done_screen.dart';
import 'package:screen_guide/features/guide/ui/error_screen.dart';
import 'package:screen_guide/features/guide/ui/guide_step_screen.dart';
import 'package:screen_guide/features/guide/ui/result_screen.dart';
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
    ScreenId.g || ScreenId.gs => GalleryScreen(flow: flow),
    ScreenId.gr => ReviewScreen(flow: flow),
    ScreenId.ga => AnalyzingScreen(flow: flow),
    ScreenId.rg => ResultScreen(flow: flow),
    ScreenId.d1 ||
    ScreenId.d2 ||
    ScreenId.d3 ||
    ScreenId.d4 ||
    ScreenId.d5 => GuideStepScreen(flow: flow),
    ScreenId.done => DoneScreen(flow: flow),
    ScreenId.e => ErrorScreen(flow: flow),
    _ => HomeScreen(flow: flow),
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
