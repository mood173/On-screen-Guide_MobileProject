import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/shared/cells/guide_scaffold.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// DONE · 안내 완료 (Figma 15:293)
class DoneScreen extends StatelessWidget {
  const DoneScreen({super.key, required this.flow});
  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    final a = flow.action!;
    return GuideScaffold(
      title: '안내 완료',
      onBack: () => flow.dispatch(ActionId.navBack),
      body: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 52,
              color: AppColors.emphasisDone,
            ),
          ),
        ),
        const Text(
          '잘 따라오셨어요!',
          textAlign: TextAlign.center,
          style: AppText.headline,
        ),
        Text(
          '${a.title} 안내 ${a.steps.length}단계를 모두 확인했어요.',
          textAlign: TextAlign.center,
          style: AppText.body,
        ),
        const WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('다음에도 쉽게 찾아보세요', style: AppText.listTitle),
              SizedBox(height: 8),
              Text(
                '사용 방법과 분석 결과만 기록에 남겨요.\n원본 사진은 저장하지 않습니다.\n이 체험에서는 실제 주문·결제가 일어나지 않아요.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
      footer: [
        PrimaryAction(
          '안내 기록에 저장',
          onPressed: flow.allows(ActionId.historySave)
              ? () => flow.dispatch(ActionId.historySave)
              : null,
        ),
        SecondaryAction(
          '새로운 화면 안내받기',
          onPressed: flow.allows(ActionId.navHome)
              ? () => flow.dispatch(ActionId.navHome)
              : null,
        ),
      ],
    );
  }
}
