import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/shared/cells/guide_scaffold.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// CP · 카메라 접근 (Figma 15:113). 카메라를 왜 쓰는지 설명하고 촬영으로 넘어간다 (시스템설계 1-3·3-3).
///
/// 배치·문구는 Figma 그대로, 두 곳만 바꿨다 (11/14 결정):
/// - 버튼 "카메라 허용 · 체험" → "카메라 허용" ("· 체험"은 시제품 표시)
/// - 카드 "사진은 분석 후 원본을 보관하지 않아요" → "찍은 사진은 안내가 끝나면 지워요"
///   (실제로는 안내 단계마다 같은 사진을 다시 분석하고, 세션이 끝날 때 복사본을 지운다 — 시스템설계 10-1)
///
/// 버튼: 카메라 허용 = `captureCamera`(기기 카메라), 지금은 허용하지 않기 = `navBack`(→ 홈).
class CameraPermissionScreen extends StatelessWidget {
  const CameraPermissionScreen({super.key, required this.flow});
  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    VoidCallback? on(ActionId id) =>
        flow.allows(id) ? () => flow.dispatch(id) : null;
    return GuideScaffold(
      title: ScreenId.cp.title, // "카메라 접근"
      onBack: () => flow.dispatch(ActionId.navBack),
      body: [
        // Figma "Permission icon": 흰 상자 64 + 보라 선 아이콘
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.photo_camera_outlined,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        // 설명 글자가 Figma에서 14라 ScreenHeading(설명 13) 대신 직접 쓴다.
        Text(
          '카메라로 화면을\n찍어볼까요?',
          style: AppText.headline.copyWith(fontSize: 27),
        ),
        const Text(
          '다른 휴대폰이나 기기의 화면을 촬영해\n버튼과 메뉴 사용법을 안내해 드려요.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Figma 카드 제목 16 (공통 listTitle은 15)
              Text(
                '카메라 접근이 필요해요',
                style: AppText.listTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                '촬영할 때만 카메라를 사용해요.\n찍은 사진은 안내가 끝나면 지워요.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.cardBody,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const Text('권한은 설정에서 언제든 바꿀 수 있어요.', style: AppText.caption),
      ],
      footer: [
        PrimaryAction('카메라 허용', onPressed: on(ActionId.captureCamera)),
        SecondaryAction('지금은 허용하지 않기', onPressed: on(ActionId.navBack)),
      ],
    );
  }
}
