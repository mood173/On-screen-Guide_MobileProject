import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart' show ShareCandidate;
import 'package:screen_guide/shared/cells/guide_scaffold.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// P · 공유 전 확인 (Figma 15:263, 시스템설계 3-8, 검토 결론 5장).
///
/// 막는 화면이 아니라 **알리는** 화면: 보내는 것은 사용 방법 글뿐이고, 이 화면에 어떤 개인정보 후보가 있었는지 알린다.
/// 받는 값은 후보 목록과 버튼 동작뿐 (검토 결론 5장 필수 "확인 화면이 받는 값은 유형과 가린 값의 목록만").
/// 흐름(GuideFlow)·기능 맵·화면 식별을 모른다 — app.dart가 목록만 꺼내 넘긴다.
///
/// 모양은 Figma, 기능은 문서 (docs/figma.md 6번): 부제는 문서 문장, 예시 대신 실제 목록,
/// "안내 기록에 저장"·"체험 화면" 문구는 뺌. "보증하지 않아요" 안내는 제약 C06이라 남긴다.
class PrivacyCheckScreen extends StatelessWidget {
  const PrivacyCheckScreen({
    super.key,
    required this.candidates,
    required this.onConfirm,
    required this.onBack,
  });

  /// 개인정보 후보 (기록에서 왔으면 가린 값 없이 유형만)
  final List<ShareCandidate> candidates;

  /// "확인했어요" → shareConfirm. 관문이 막으면 null.
  final VoidCallback? onConfirm;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final n = candidates.length;
    return GuideScaffold(
      title: '공유 전 확인',
      onBack: onBack,
      body: [
        const SizedBox(height: 8),
        const Icon(Icons.shield_outlined, size: 64, color: AppColors.caution),
        const Text('공유하기 전에\n한 번 더 확인해요', style: AppText.pageTitle),
        // 검토 결론 5장 "확인 화면의 뜻" 문장 그대로 (0건은 같은 말투로 정함)
        Text(
          n > 0
              ? '이 화면에는 개인정보 후보 $n건이 있었어요.\n보내는 것은 사용 방법 글뿐이에요.'
              : '개인정보 후보는 찾지 못했어요.\n보내는 것은 사용 방법 글뿐이에요.',
          style: AppText.body,
        ),
        WhiteCard(
          color: AppColors.privacySurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '개인정보 후보 $n건',
                style: AppText.section.copyWith(color: AppColors.privacyTitle),
              ),
              const SizedBox(height: 12),
              // 같은 유형도 줄마다 하나씩 (위의 "N건"과 줄 수가 같게)
              for (final c in candidates)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    c.masked == null
                        ? '·  ${c.type}'
                        : '·  ${c.type}   ${c.masked}',
                    style: AppText.body.copyWith(color: AppColors.privacyBody),
                  ),
                ),
              if (n > 0) const SizedBox(height: 6),
              // 제약 C06 (기능·개념 정리 178줄) — 0건일 때 특히 필요
              Text(
                '검사는 주의를 돕는 기능이며,\n개인정보가 없음을 보증하지 않아요.',
                style: AppText.body.copyWith(color: AppColors.privacyBody),
              ),
            ],
          ),
        ),
      ],
      footer: [PrimaryAction('확인했어요 · 사용 방법만 공유', onPressed: onConfirm)],
    );
  }
}
