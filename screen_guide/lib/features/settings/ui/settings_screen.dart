import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/shared/cells/app_tab_bar.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// SETTINGS · 설정 (Figma 15:275, 시스템설계 3-9, 일정_현실검토 3-2 [제안] "권한 상태와 맵 revision 두 줄").
///
/// 모양은 Figma, 기능은 문서 (11/22 결정, docs/figma.md 5번):
/// - 권한은 상태 글자 없이 "권한 관리" 줄로 기기 설정을 연다 (결정 ㉮: 묻지 않고 상태만 읽는 포트가 없다)
/// - 기능 맵 revision은 "안내 자료 버전" 카드로 (역할설계 D7)
/// - 동기화 동의는 그리지 않는다 (시스템설계 8장 "되면 넣는다", 협업규격 8장 8번 팀 결정 대기)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.flow});
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
              // 앱 셸이라 ‹ 없이 제목만 (4-1). 뒤로는 기기 뒤로 키 → navBack
              const SizedBox(
                height: 60,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('설정', style: AppText.toolbar),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    const Text('편리하게, 안심하고', style: AppText.headline),
                    const SizedBox(height: AppSpace.section),
                    const Text('화면길잡이  ·  BETA 2', style: AppText.caption),
                    const SizedBox(height: AppSpace.section),
                    // 회색 줄 버튼 = 앱 테마의 글자 버튼 (Figma #EEF0F7, 모서리 16, 높이 52)
                    TextButton(
                      key: const ValueKey('settings-permission'),
                      onPressed: _on(flow, ActionId.settingsOpenPermission),
                      child: const Text('카메라·사진 권한 관리'),
                    ),
                    const SizedBox(height: AppSpace.section),
                    TextButton(
                      key: const ValueKey('settings-history'),
                      onPressed: _on(flow, ActionId.navHistory),
                      child: const Text('저장한 안내 기록'),
                    ),
                    const SizedBox(height: AppSpace.section),
                    _MapVersionCard(revision: flow.mapRevision),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: AppTabBar(
                  active: AppTab.settings,
                  onHome: _on(flow, ActionId.navHome),
                  onHistory: _on(flow, ActionId.navHistory),
                  onSettings: _on(flow, ActionId.navSettings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 안내 자료(기능 맵) 버전 카드. Figma "About beta" 카드 모양에 문서의 revision 줄을 담는다.
class _MapVersionCard extends StatelessWidget {
  const _MapVersionCard({required this.revision});
  final String? revision;

  /// 기능 맵을 못 읽었을 때 구현이 돌려주는 값.
  /// 화면은 data/를 import할 수 없어(팀 의존 규칙) 글자를 직접 쓴다.
  /// 원본은 최정혁의 AssetGuidanceRepository.unavailableRevision — 값이 바뀌면 settings_screen_test가 실패한다.
  static const _unavailable = 'unavailable';

  @override
  Widget build(BuildContext context) {
    final r = revision;
    final shown = (r == null || r.isEmpty || r == _unavailable)
        ? '확인할 수 없어요'
        : r;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('안내 자료 버전', style: AppText.section),
          const SizedBox(height: 12),
          Text(
            shown,
            key: const ValueKey('map-revision'),
            style: AppText.body.copyWith(color: AppColors.cardBody),
          ),
          const SizedBox(height: 4),
          Text(
            '안내 자료는 기기 안에 있어서 인터넷 없이도 안내해요.',
            style: AppText.body.copyWith(color: AppColors.cardBody),
          ),
        ],
      ),
    );
  }
}

/// 관문이 허용할 때만 눌리는 버튼 동작 (홈·기록 화면과 같은 함수. 공용으로 빼면 import 규칙을 바꿔야 해서 각자 둔다)
VoidCallback? _on(GuideFlow flow, ActionId id) =>
    flow.allows(id) ? () => flow.dispatch(id) : null;
