import 'package:flutter/material.dart';

import 'package:screen_guide/shared/theme/app_tokens.dart';

/// 앱 셸의 하단 탭 3개 (시스템설계 4-1: 대기·기록·설정이 같이 쓴다. Figma 14:114 하단).
enum AppTab { home, history, settings }

/// 하단 탭. 흐름을 모른다 — 팀 규칙 "shared/는 app/을 보지 않는다"(dependency_rules_test).
///
/// 탭마다 "눌렀을 때 할 일"만 받는다. 누를 수 없으면 null을 받아 눌리지 않는다.
/// 누를 수 있는지는 화면이 관문(`flow.allows`)에 물어 정한다 (4-2 규칙 2). `GuideScaffold.onBack`과 같은 방식.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.active,
    required this.onHome,
    required this.onHistory,
    required this.onSettings,
  });

  /// 지금 화면의 탭 (진하게 그린다)
  final AppTab active;
  final VoidCallback? onHome;
  final VoidCallback? onHistory;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    Widget item(AppTab tab, String label, VoidCallback? onTap) {
      final on = tab == active;
      return Expanded(
        child: InkWell(
          key: ValueKey('tab-${tab.name}'),
          // 지금 탭을 다시 눌러도 할 일이 없으니 막는다
          onTap: on ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: AppText.tab.copyWith(
                color: on ? AppColors.primary : AppColors.textSecondary,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          item(AppTab.home, '⌂  홈', onHome),
          item(AppTab.history, '◷  기록', onHistory),
          item(AppTab.settings, '⚙  설정', onSettings),
        ],
      ),
    );
  }
}
