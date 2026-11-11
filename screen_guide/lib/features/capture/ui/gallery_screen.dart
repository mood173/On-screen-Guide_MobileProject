import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/shared/cells/guide_scaffold.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// G · 최근 이미지 (Figma 15:143) / GS · 이미지 선택 (Figma 15:149)
///
/// 흐름이 GalleryInput.recent()로 받아 둔 최근 사진(최대 9장)을 그린다. 정지 이미지 1개만 고를 수 있다 (C01).
/// 앨범 고르기·더 불러오기는 없다 (기능별_검토_결론 13장 X3·X4).
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key, required this.flow});
  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    final selecting = flow.selectedId != null; // GS
    final items = flow.galleryItems;
    VoidCallback? on(ActionId id) =>
        flow.allows(id) ? () => flow.dispatch(id) : null;
    return GuideScaffold(
      title: selecting ? '이미지 선택' : '최근 이미지',
      onBack: () => flow.dispatch(ActionId.navBack),
      body: [
        ScreenHeading(
          selecting ? '이 이미지를 쓸까요?' : '안내받을 화면을 골라 주세요',
          '최근 스크린샷  ·  한 번에 1개만 선택할 수 있어요',
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('최근 사진이 없어요', style: AppText.caption)),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.52,
            children: [
              for (final it in items)
                _Thumb(
                  item: it,
                  selected: flow.selectedId == it.id,
                  onTap: flow.allows(ActionId.capturePick)
                      ? () => flow.dispatch(ActionId.capturePick, it.id)
                      : null,
                ),
            ],
          ),
      ],
      footer: selecting
          ? [
              PrimaryAction(
                '선택한 이미지 사용',
                onPressed: on(ActionId.captureConfirm),
              ),
              SecondaryAction('선택 해제', onPressed: on(ActionId.captureRetake)),
            ]
          : const [],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final GalleryItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('thumb-${item.id}'),
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
                    child: Image.memory(
                      item.thumbnail,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: AppColors.surface,
                        child: Center(child: Icon(Icons.image_outlined)),
                      ),
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
            item.kind == GalleryKind.screenshot ? '스크린샷' : '사진',
            style: AppText.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
