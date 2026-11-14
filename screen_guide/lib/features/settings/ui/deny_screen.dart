import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/shared/cells/guide_scaffold.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// DENY · 권한이 필요해요 (Figma 15:287).
///
/// 배치는 Figma 그대로: 왼쪽 위 아이콘 상자 → 큰 글씨 28 → 부제 → 흰 카드 → 하단 버튼.
/// 문구는 거부된 입력 방식(`flow.deniedInput`)으로 고른다 — Figma는 한 가지 문구지만
/// 문서(기능별_검토_결론, 필수)가 "입력 방식별 문구"를 정해서 문서를 따른다.
/// Figma의 "실시간 권한 확인" 버튼은 뺀다 (13장 X5: 실시간 안내 제외).
///
/// 버튼 둘 (시스템설계 3-9): 권한 확인 = 기기 설정 열기(`settingsOpenPermission`),
/// 갤러리(`captureGallery`) = 갤러리 열기 — 카메라 거부면 "갤러리에서 선택"(대신하기),
/// 갤러리 거부면 설정에서 허용하고 돌아와 "다시 시도". 하는 일은 같고 이름만 다르다.
class DenyScreen extends StatelessWidget {
  const DenyScreen({super.key, required this.flow});
  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    final camera = flow.deniedInput == InputKind.camera;
    VoidCallback? on(ActionId id) =>
        flow.allows(id) ? () => flow.dispatch(id) : null;
    return GuideScaffold(
      title: ScreenId.deny.title, // "권한이 필요해요"
      onBack: () => flow.dispatch(ActionId.navBack),
      body: [
        // Figma "State icon": 흰 상자 64 + 주황 선 아이콘
        // 화면 틀(GuideScaffold)이 내용을 가로로 꽉 채워서, 64 크기를 지키려면 왼쪽 정렬로 감싼다
        // (11/14 에뮬레이터에서 상자가 화면 너비로 늘어난 것을 발견).
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            key: const ValueKey('icon-box'), // 시험이 64 크기를 확인한다
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              camera ? Icons.no_photography_outlined : Icons.lock_outline,
              size: 40,
              color: AppColors.caution,
            ),
          ),
        ),
        ScreenHeading(
          camera ? '카메라 권한이\n허용되지 않았어요' : '사진 접근 권한이\n허용되지 않았어요',
          '원하는 입력 방식의 권한을 다시 확인해 주세요.',
          size: 28,
        ),
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                camera ? '다른 방법으로도 시작할 수 있어요' : '이렇게 다시 시도해 보세요',
                style: AppText.listTitle.copyWith(fontSize: 16), // Figma 16
              ),
              const SizedBox(height: 12),
              Text(
                camera
                    ? '카메라 권한을 거부해도 갤러리는 선택할 수 있어요.'
                    : '기기 설정에서 이 앱의 사진 접근을 허용한 뒤\n"다시 시도"를 눌러 주세요.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.cardBody,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
      footer: [
        PrimaryAction(
          camera ? '카메라 권한 확인' : '사진 권한 확인',
          onPressed: on(ActionId.settingsOpenPermission),
        ),
        SecondaryAction(
          camera ? '갤러리에서 선택' : '다시 시도',
          onPressed: on(ActionId.captureGallery),
        ),
      ],
    );
  }
}
