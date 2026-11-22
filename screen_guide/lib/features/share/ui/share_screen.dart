import 'package:flutter/material.dart';

import 'package:screen_guide/shared/cells/guide_scaffold.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// SHARE · 공유하기 (Figma 15:299, 시스템설계 3-8 "보낼 텍스트 미리보기").
///
/// 받는 값은 보낼 글과 버튼 동작뿐. 흐름(GuideFlow)·분석 결과를 모른다 — app.dart가 `flow.shareText`를 꺼내 넘긴다.
/// 미리보기 글 = 실제로 보낼 글 (같은 buildShareText 결과). 글자를 바꾸지 않고 그대로 보여 준다.
///
/// 모양은 Figma, 기능은 문서 (docs/figma.md 8번): 주 버튼 "공유 완료 · 체험" → "보내기", "체험 화면" 문구는 뺌.
class ShareScreen extends StatelessWidget {
  const ShareScreen({
    super.key,
    required this.text,
    required this.onSend,
    required this.onBack,
  });

  /// 보낼 글 (첫 줄 = "기능 제목 · 사용 방법")
  final String text;

  /// "보내기" → shareSend. 관문이 막으면(공유 중 등) null.
  final VoidCallback? onSend;

  /// ‹ 와 "돌아가기" → navBack (SHARE → P 한 칸, 결정 ㉮)
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    // 첫 줄은 카드 제목처럼 굵게, 나머지는 그대로. 글자는 하나도 바꾸지 않는다.
    final cut = text.indexOf('\n');
    final head = cut < 0 ? text : text.substring(0, cut);
    final rest = cut < 0 ? '' : text.substring(cut + 1);
    return GuideScaffold(
      title: '공유하기',
      onBack: onBack,
      body: [
        const SizedBox(height: 8),
        const Icon(Icons.ios_share_rounded, size: 64, color: AppColors.caution),
        const Text('공유할 내용을\n확인해 주세요', style: AppText.pageTitle),
        const Text('원본 이미지 없이 사용 방법만 공유합니다.', style: AppText.body),
        WhiteCard(
          key: const ValueKey('share-preview'),
          color: AppColors.privacySurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                head,
                style: AppText.section.copyWith(color: AppColors.privacyTitle),
              ),
              if (rest.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  rest,
                  style: AppText.body.copyWith(
                    color: AppColors.privacyBody,
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      footer: [
        PrimaryAction('보내기', onPressed: onSend),
        SecondaryAction('돌아가기', onPressed: onBack),
      ],
    );
  }
}
