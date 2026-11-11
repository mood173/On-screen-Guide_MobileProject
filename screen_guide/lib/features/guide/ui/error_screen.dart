import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/shared/cells/guide_scaffold.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/contracts/error_code.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// E · 다시 시도 (Figma 15:281). 오류 코드만 보고 문구를 고른다 (설계 4장).
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.flow});
  final GuideFlow flow;

  static (String, String) _copy(ErrorCode? c) => switch (c) {
    ErrorCode.unknownScreen => (
      '어떤 화면인지 알 수 없어요',
      '지원하는 앱 화면인지 확인하고 화면 전체가 보이게 다시 찍어 주세요.',
    ),
    ErrorCode.noTarget => (
      '누를 곳을 찾지 못했어요',
      '화면이 바뀌었거나 흐릴 수 있어요. 추정해서 안내하지 않아요.',
    ),
    ErrorCode.imageReadFailed => (
      '이미지를 열 수 없어요',
      '파일이 손상되었을 수 있어요. 다른 이미지를 골라 주세요.',
    ),
    ErrorCode.noPath => ('이미지를 찾을 수 없어요', '다른 이미지를 골라 주세요.'),
    ErrorCode.permissionDenied => (
      '사진에 접근할 수 없어요',
      '기기 설정에서 이 앱의 사진 접근을 허용해 주세요.',
    ),
    _ => ('분석하지 못했어요', '잠시 후 다시 시도해 주세요.'),
  };

  @override
  Widget build(BuildContext context) {
    final (title, tip) = _copy(flow.error);
    final camera = flow.input == InputKind.camera;
    VoidCallback? on(ActionId id) =>
        flow.allows(id) ? () => flow.dispatch(id) : null;
    return GuideScaffold(
      title: '다시 시도',
      onBack: () => flow.dispatch(ActionId.navBack),
      body: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.privacySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.refresh_rounded,
              size: 50,
              color: AppColors.caution,
            ),
          ),
        ),
        Text(
          camera ? '다시 촬영해 주세요' : '다시 골라 주세요',
          textAlign: TextAlign.center,
          style: AppText.headline.copyWith(fontSize: 25),
        ),
        Text(title, textAlign: TextAlign.center, style: AppText.listTitle),
        WhiteCard(
          child: Text(
            tip,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
        Text(
          '오류 코드: ${flow.error?.wire ?? '-'}',
          textAlign: TextAlign.center,
          style: AppText.caption,
        ),
      ],
      // 세션의 입력 방식에 맞는 복구 버튼만 (기능별_검토_결론 8장). 실시간 다시 스캔은 오버레이가 붙을 때.
      footer: camera
          ? [
              PrimaryAction('다시 촬영', onPressed: on(ActionId.captureCamera)),
              SecondaryAction(
                '갤러리에서 고르기',
                onPressed: on(ActionId.captureGallery),
              ),
            ]
          : [
              PrimaryAction('다른 이미지 선택', onPressed: on(ActionId.captureRetake)),
              SecondaryAction('처음으로', onPressed: on(ActionId.navHome)),
            ],
    );
  }
}
