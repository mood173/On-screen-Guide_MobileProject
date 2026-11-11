import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/shared/cells/guide_scaffold.dart';
import 'package:screen_guide/shared/cells/screen_image.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// D1~D5 · 단계별 안내 (Figma 15:233 ~ 15:257)
///
/// 위쪽 진행 막대(n/N), 목표 UI 인디고 테두리, 안내 카드(#EFEEFF), "다음 단계" / "화면이 달라요 · 다시 분석".
/// 단계가 바뀌면 카드가 옆으로 넘어간다 (설계 6.2: 흐름은 애니메이션을 기다리지 않음).
class GuideStepScreen extends StatelessWidget {
  const GuideStepScreen({super.key, required this.flow});
  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    final img = flow.picked!;
    final s = flow.currentStep!;
    final n = flow.step + 1, total = flow.totalSteps;
    VoidCallback? on(ActionId id) =>
        flow.allows(id) ? () => flow.dispatch(id) : null;
    return GuideScaffold(
      title: '단계별 안내 · $n / $total',
      onBack: () => flow.dispatch(ActionId.navBack),
      body: [
        _Progress(value: n / total),
        Text(flow.action!.title, style: AppText.title),
        Stack(
          children: [
            ScreenImage(
              asset: img.asset,
              imageWidth: img.width,
              imageHeight: img.height,
              target: flow.target?.box,
              dimOthers: true,
              height: 350,
            ),
            if (flow.locating)
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, a) => SlideTransition(
            position: Tween(
              begin: const Offset(0.15, 0),
              end: Offset.zero,
            ).animate(a),
            child: FadeTransition(opacity: a, child: child),
          ),
          child: Container(
            key: ValueKey(flow.step),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.instructionPad),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.instruction, style: AppText.instructionTitle),
                const SizedBox(height: 6),
                Text(
                  flow.locating ? '화면에서 위치를 확인하고 있어요…' : s.result,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.instructionSub,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      footer: [
        PrimaryAction(
          n == total ? '안내 완료' : '다음 단계',
          onPressed: on(ActionId.guideNext),
        ),
        SecondaryAction(
          '화면이 달라요 · 다시 분석',
          onPressed: on(ActionId.guideMismatch),
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(3),
    child: TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 300),
      builder: (context, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: AppSpace.progressHeight,
        color: AppColors.primary,
        backgroundColor: AppColors.divider,
      ),
    ),
  );
}
