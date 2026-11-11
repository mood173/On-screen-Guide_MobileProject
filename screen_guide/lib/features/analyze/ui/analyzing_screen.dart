import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/shared/cells/guide_scaffold.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// GA · 이미지 분석 중 (Figma 15:161)
///
/// 체크 3개는 연출이다. 채널은 결과를 한 번에 돌려주므로 단계별 진행 근거가 없다(설계 6.2 주의).
/// 3초가 넘으면 오류로 끊지 않고 "조금 더 걸리고 있어요"를 보여 준다(계약 v1 결정 3).
class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key, required this.flow});
  final GuideFlow flow;

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.flow;
    return GuideScaffold(
      title: '이미지 분석 중',
      onBack: () => flow.dispatch(ActionId.navBack),
      body: [
        const ScreenHeading(
          '화면 속 길을\n찾고 있어요',
          '갤러리 선택 · 기기 내부에서 처리 중',
          size: 28,
        ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primarySoft,
                ),
              ),
              if (flow.slow) ...[
                const SizedBox(height: 16),
                const Text('조금 더 걸리고 있어요', style: AppText.listTitle),
              ],
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            String row(int i, String label) =>
                '${_anim.value > (i + 1) / 3.2 ? '✓' : '◌'}  $label';
            return WhiteCard(
              child: Text(
                [
                  row(0, '화면의 버튼과 메뉴 확인'),
                  row(1, '개인정보 포함 가능성 확인'),
                  row(2, '사용 순서 정리 중'),
                ].join('\n'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF637087),
                  height: 1.6,
                ),
              ),
            );
          },
        ),
        const Text('원본 이미지는 저장하거나 전송하지 않아요.', style: AppText.caption),
      ],
      footer: [
        if (flow.slow) PrimaryAction('계속 기다리기', onPressed: () {}),
        SecondaryAction(
          '분석 취소',
          onPressed: () => flow.dispatch(ActionId.analyzeCancel),
        ),
      ],
    );
  }
}
