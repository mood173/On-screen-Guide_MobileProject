import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// H · 홈 (Figma 14:114)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.flow});
  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 60,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('화면길잡이', style: AppText.toolbar),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '어려운 화면도,\n이제 한 번에 이해해요.',
                        style: AppText.headline,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '사진 한 장으로 시작하는 나만의 앱 가이드',
                        style: AppText.body,
                      ),
                      const SizedBox(height: 16),
                      const _Hero(),
                      const SizedBox(height: 16),
                      const Text('어떤 방법으로 시작할까요?', style: AppText.section),
                      const SizedBox(height: 16),
                      _InputTile(
                        key: const ValueKey('input-camera'),
                        icon: Icons.photo_camera_outlined,
                        tile: AppColors.tileCamera,
                        iconColor: AppColors.primary,
                        title: '카메라 촬영',
                        subtitle: '다른 기기의 화면을 찍어서 안내받기',
                        onTap: () => flow.dispatch(ActionId.captureCamera),
                      ),
                      const SizedBox(height: 16),
                      _InputTile(
                        key: const ValueKey('input-gallery'),
                        icon: Icons.image_outlined,
                        tile: AppColors.tileGallery,
                        iconColor: AppColors.tileGalleryIcon,
                        title: '갤러리에서 선택',
                        subtitle: '저장한 스크린샷이나 사진 불러오기',
                        onTap: () => flow.dispatch(ActionId.captureGallery),
                      ),
                      const SizedBox(height: 16),
                      _InputTile(
                        key: const ValueKey('input-live'),
                        icon: Icons.center_focus_strong_outlined,
                        tile: AppColors.tileLive,
                        iconColor: AppColors.tileLiveIcon,
                        title: '화면 실시간 스캔',
                        subtitle: '다른 앱 위에서 바로 안내받기',
                        onTap: () => flow.dispatch(ActionId.overlaySetup),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: _BottomNav(flow: flow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.cardPadLarge),
      decoration: BoxDecoration(
        color: AppColors.hero,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 폰 안에서, 안전하게',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '화면을 읽고 다음 행동을 알려드려요.\n원본 이미지는 외부로 보내지 않아요.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.heroSub,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ON-DEVICE AI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.heroAccent,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '오프라인에서도 편리하게',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({
    super.key,
    required this.icon,
    required this.tile,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tile, iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.cardPad),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tile,
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.listTitle),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppText.caption.copyWith(fontSize: 10),
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
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.flow});
  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, bool active, VoidCallback onTap) => Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            label,
            style: AppText.tab.copyWith(
              color: active ? AppColors.primary : AppColors.textSecondary,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          item('⌂  홈', true, () {}),
          item('◷  기록', false, () => flow.dispatch(ActionId.historyOpen)),
          item(
            '⚙  설정',
            false,
            () => flow.dispatch(ActionId.settingsOpenPermission),
          ),
        ],
      ),
    );
  }
}
