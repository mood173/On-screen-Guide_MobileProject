import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/shared/cells/guide_scaffold.dart';
import 'package:screen_guide/shared/cells/screen_image.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

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
    VoidCallback? on(ActionId id, [Object? arg]) =>
        flow.allows(id) ? () => flow.dispatch(id, arg) : null;
    return GuideScaffold(
      title: '분석 결과',
      onBack: () => flow.dispatch(ActionId.navBack),
      body: [
        ScreenHeading(
          '무엇을 하고 싶으세요?',
          '글자 ${r.elements.length}개를 읽었어요  ·  ${r.totalMs}ms',
        ),
        ScreenImage(
          path: img.path!,
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
        if (actions.isEmpty)
          const WhiteCard(
            key: ValueKey('no-actions'),
            child: Text('이 화면에서 안내할 수 있는 기능이 아직 없어요', style: AppText.body),
          ),
        for (final a in actions)
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InkWell(
              key: ValueKey('action-${a.actionId}'),
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: on(ActionId.guideStart, a),
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
      // "결과 저장 및 공유"는 이번에 넣지 않는다 (기능별_검토_결론 13장 X1: 기능을 고르기 전에는 공유할 사용 방법이 없다)
      footer: [
        if (actions.isEmpty)
          PrimaryAction('다른 이미지 선택', onPressed: on(ActionId.captureRetake)),
      ],
    );
  }
}
