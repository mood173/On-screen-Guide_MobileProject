import 'package:flutter/material.dart';

import '../../core/action_id.dart';
import '../../runtime/guide_flow.dart';
import '../cell/guide_scaffold.dart';
import '../cell/screen_image.dart';
import '../theme/app_tokens.dart';

/// RG · 갤러리 분석 결과 (Figma 15:167)
///
/// 미리보기(인식한 요소 테두리) + 이 화면에서 안내받을 수 있는 기능 목록 + 개인정보 후보 요약.
/// 기능 입력은 중간 보고서 기준(12.1 ①)대로 목록에서 고르는 방식이다.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.flow});
  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    final img = flow.picked!;
    final r = flow.result!;
    final actions = flow.availableActions;
    return GuideScaffold(
      title: '분석 결과',
      onBack: () => flow.dispatch(ActionId.navBack),
      body: [
        ScreenHeading(
          '무엇을 하고 싶으세요?',
          '버튼과 메뉴 ${r.elements.length}개를 찾았어요  ·  ${r.totalMs}ms',
        ),
        ScreenImage(
          asset: img.asset,
          imageWidth: r.imageWidth,
          imageHeight: r.imageHeight,
          elements: r.elements,
          height: 260,
        ),
        if (r.pii.isNotEmpty)
          WhiteCard(
            color: AppColors.privacySurface,
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.caution),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '개인정보 후보 ${r.pii.length}건이 보여요. 공유하기 전에 확인해 주세요.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.privacyTitle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Text('추천 기능', style: AppText.section),
        for (final a in actions)
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InkWell(
              key: ValueKey('action-${a.actionId}'),
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: () => flow.dispatch(ActionId.guideStart, a),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.cardPad + 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: AppText.listTitle),
                          const SizedBox(height: 2),
                          Text(
                            '${a.description}  ·  ${a.steps.length}단계',
                            style: AppText.caption,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '›',
                      style: TextStyle(fontSize: 23, color: AppColors.chevron),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
      footer: [
        SecondaryAction(
          '결과 저장 및 공유',
          onPressed: () => flow.dispatch(ActionId.sharePrepare),
        ),
      ],
    );
  }
}
