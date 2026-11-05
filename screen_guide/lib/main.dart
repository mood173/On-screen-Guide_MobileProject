import 'package:flutter/material.dart';

import 'bootstrap.dart';
import 'contract/analysis.dart';

void main() {
  runApp(ScreenGuideApp(deps: bootstrap()));
}

class ScreenGuideApp extends StatelessWidget {
  const ScreenGuideApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '화면길잡이',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: SkeletonHome(deps: deps),
    );
  }
}

/// 골격 확인용 임시 화면. 화면·흐름 담당이 실제 H(홈) 화면으로 바꾼다.
///
/// 버튼을 누르면 bootstrap()이 고른 분석기로 계약 v1 예시 요청을 한 번 보내고 결과 요약을 보여 준다.
class SkeletonHome extends StatefulWidget {
  const SkeletonHome({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<SkeletonHome> createState() => _SkeletonHomeState();
}

class _SkeletonHomeState extends State<SkeletonHome> {
  String _summary = '';
  bool _busy = false;

  static const _sampleRequest = AnalyzeRequest(
    requestId: 'skeleton-1',
    imagePath: '',
    guidance: GuidanceFragment(
      packageName: 'com.android.settings',
      screens: [
        ScreenAnchors(screenId: 'settings', anchors: ['설정', '알림 설정', '디스플레이']),
      ],
    ),
    target: TargetRequest(
      actionId: 'settings.notification',
      stepIndex: 0,
      selector: '알림 설정',
    ),
  );

  Future<void> _run() async {
    setState(() => _busy = true);
    final r = await widget.deps.analyzer.analyze(_sampleRequest);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _summary = r.ok
          ? '화면: ${r.screenId ?? "미식별"}\n'
              '요소 ${r.elements.length}개 · 대상: ${r.target?.label ?? "없음"}\n'
              '개인정보 후보 ${r.pii.length}건 · ${r.totalMs}ms'
          : '오류: ${r.errorCode?.wire}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('화면길잡이 (골격)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '분석기: ${useFakeAnalyzer ? "가짜(FakeAnalyzer)" : "Kotlin 채널"}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _run,
              child: Text(_busy ? '분석 중…' : '예시 요청 보내기'),
            ),
            const SizedBox(height: 16),
            Text(_summary, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
