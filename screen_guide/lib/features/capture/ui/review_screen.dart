import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/shared/cells/guide_scaffold.dart';
import 'package:screen_guide/shared/cells/screen_image.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// GR · 선택한 이미지 (Figma 15:155) / CR · 촬영한 사진 (15:125).
/// 같은 장면이라 위젯 하나, 입력 방식만 다르다 (시스템설계 3-0).
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.flow});
  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    final img = flow.picked!;
    final camera = img.input == InputKind.camera;
    VoidCallback? on(ActionId id) =>
        flow.allows(id) ? () => flow.dispatch(id) : null;
    // 문구는 Figma GR(15:155) / CR(15:125) 그대로. 위젯은 하나, 입력 방식으로 문구만 고른다.
    return GuideScaffold(
      title: flow.screen.title, // GR "선택한 이미지" / CR "촬영한 사진"
      onBack: () => flow.dispatch(ActionId.navBack),
      body: [
        camera
            ? const ScreenHeading('촬영한 화면을 확인하세요', '카메라 촬영  ·  방금 전')
            : const ScreenHeading('이 이미지로 안내받을까요?', '갤러리에서 선택  ·  이미지 1개'),
        ScreenImage(path: img.path!, height: 350),
        if (camera)
          const Text(
            '화면 전체를 맞춰주세요',
            textAlign: TextAlign.center,
            style: AppText.caption,
          ),
        const Text(
          '✓  원본 미전송     ✓  기기 내부 분석',
          style: TextStyle(fontSize: 12, color: AppColors.tileGalleryIcon),
        ),
      ],
      footer: [
        PrimaryAction('이 화면 분석하기', onPressed: on(ActionId.analyzeRun)),
        SecondaryAction(
          camera ? '다시 촬영' : '다른 이미지 선택',
          onPressed: on(ActionId.captureRetake),
        ),
      ],
    );
  }
}
