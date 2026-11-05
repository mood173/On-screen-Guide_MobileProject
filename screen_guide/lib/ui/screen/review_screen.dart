import 'package:flutter/material.dart';

import '../../core/action_id.dart';
import '../../runtime/guide_flow.dart';
import '../cell/guide_scaffold.dart';
import '../cell/screen_image.dart';
import '../theme/app_tokens.dart';

/// GR · 선택한 이미지 (Figma 15:155)
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.flow});
  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    final img = flow.picked!;
    VoidCallback? on(ActionId id) =>
        flow.allows(id) ? () => flow.dispatch(id) : null;
    return GuideScaffold(
      title: '선택한 이미지',
      onBack: () => flow.dispatch(ActionId.navBack),
      body: [
        ScreenHeading('이 이미지로 안내받을까요?', '갤러리에서 선택  ·  ${img.label} 1개'),
        ScreenImage(
          asset: img.asset,
          imageWidth: img.width,
          imageHeight: img.height,
          height: 350,
        ),
        const Text(
          '✓  원본 미전송     ✓  기기 내부 분석',
          style: TextStyle(fontSize: 12, color: AppColors.tileGalleryIcon),
        ),
      ],
      footer: [
        PrimaryAction('이 화면 분석하기', onPressed: on(ActionId.analyzeRun)),
        SecondaryAction('다른 이미지 선택', onPressed: on(ActionId.captureRetake)),
      ],
    );
  }
}
