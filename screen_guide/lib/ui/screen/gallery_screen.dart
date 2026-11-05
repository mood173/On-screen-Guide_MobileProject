import 'package:flutter/material.dart';

import '../../core/action_id.dart';
import '../../data/sample_images.dart';
import '../../runtime/guide_flow.dart';
import '../cell/guide_scaffold.dart';
import '../theme/app_tokens.dart';

/// G · 최근 이미지 (Figma 15:143) / GS · 이미지 선택 (Figma 15:149)
///
/// image_picker가 들어오기 전까지는 체험용 샘플 이미지 목록을 보여 준다. 정지 이미지 1개만 고를 수 있다(C01).
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key, required this.flow});
  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    final selecting = flow.picked != null; // GS
    return GuideScaffold(
      title: selecting ? '이미지 선택' : '최근 이미지',
      onBack: () => flow.dispatch(ActionId.navBack),
      body: [
        ScreenHeading(
          selecting ? '이 이미지를 쓸까요?' : '안내받을 화면을 골라 주세요',
          '최근 스크린샷  ·  한 번에 1개만 선택할 수 있어요',
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.52,
          children: [
            for (final s in SampleImage.all)
              _Thumb(
                sample: s,
                selected: flow.picked?.id == s.id,
                onTap: () => flow.dispatch(ActionId.captureGallery, s),
              ),
          ],
        ),
      ],
      footer: selecting
          ? [
              PrimaryAction(
                '선택한 이미지 사용',
                onPressed: () => flow.dispatch(ActionId.captureGallery),
              ),
              SecondaryAction(
                '선택 해제',
                onPressed: () => flow.dispatch(ActionId.captureRetake),
              ),
            ]
          : const [],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.sample,
    required this.selected,
    required this.onTap,
  });
  final SampleImage sample;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('thumb-${sample.id}'),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.tile + 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                    child: Image.asset(
                      sample.asset,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.check, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sample.label,
            style: AppText.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
