import 'package:flutter/material.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/history/domain/history.dart';
import 'package:screen_guide/shared/cells/app_tab_bar.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// HISTORY · 내 안내 기록 (Figma 15:269, 시스템설계 3-9).
///
/// 모양은 Figma, 기능은 문서 (11/22 결정, docs/figma.md 4번):
/// 앱 셸 하단 탭, 줄마다 지우기 + 한 번 확인, 기록 줄 = 기능 제목 / 입력 방식 · 시각.
/// 화면은 흐름의 값(`historyItems`, `openedEntry`)만 그린다. 공유 버튼은 4.2 5번 5-4에서.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.flow});
  final GuideFlow flow;

  @override
  Widget build(BuildContext context) {
    final items = flow.historyItems;
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
                  child: Text('내 안내 기록', style: AppText.toolbar),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    const Text('내가 찾은 사용법', style: AppText.pageTitle),
                    const SizedBox(height: AppSpace.section),
                    const Text('필요할 때 다시 꺼내보세요.', style: AppText.body),
                    const SizedBox(height: AppSpace.section),
                    Text('최근 안내  ·  ${items.length}개', style: AppText.caption),
                    const SizedBox(height: AppSpace.section),
                    if (items.isEmpty) const _Empty(),
                    for (final e in items) ...[
                      _EntryCard(
                        entry: e,
                        opened: flow.openedEntry?.id == e.id,
                        onOpen: _on(flow, ActionId.historyOpen, e.id),
                        onDelete: flow.allows(ActionId.historyDelete)
                            ? () => _confirmDelete(context, e.id)
                            : null,
                      ),
                      const SizedBox(height: AppSpace.section),
                    ],
                    const _StorageNote(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: AppTabBar(
                  active: AppTab.history,
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

  /// 지우기는 되돌릴 수 없으므로 한 번 확인한다 (3-9 규칙).
  /// 확인창은 화면 전용 상태라 흐름은 모른다 (4-2 규칙 3). [지우기]를 누를 때만 historyDelete를 보낸다.
  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 기록을 지울까요?'),
        content: const Text('지운 기록은 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            style: _smallButton,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            style: _smallButton,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('지우기'),
          ),
        ],
      ),
    );
    if (ok == true) await flow.dispatch(ActionId.historyDelete, id);
  }
}

/// 기록 줄 (4-2 "기록 줄: 제목, 시각 → historyOpen(id)" + 3-9 지우기).
/// 누르면 그 자리에서 단계 문구가 펼쳐진다 (9장 "단계 문구 목록"). 닫기는 기기 뒤로 키.
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.opened,
    required this.onOpen,
    required this.onDelete,
  });

  final HistoryEntry entry;
  final bool opened;
  final VoidCallback? onOpen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('history-${entry.id}'),
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 52,
                ), // Figma 줄 높이 76 = 52 + 안쪽 12×2
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.actionTitle,
                            style: AppText.button.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_inputLabel(entry.input)}  ·  ${_when(entry.createdAt)}',
                            style: AppText.caption,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: _smallButton,
                      key: ValueKey('delete-${entry.id}'),
                      onPressed: onDelete,
                      child: const Text('지우기'),
                    ),
                  ],
                ),
              ),
              if (opened) ...[
                const Divider(color: AppColors.divider),
                for (var i = 0; i < entry.stepInstructions.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${i + 1}. ${entry.stepInstructions[i]}',
                      style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 기록이 0건일 때 (문서·Figma에 없어 정한 문구. 버튼 이름은 완료 화면과 같게)
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpace.section),
      child: Text(
        "아직 저장한 안내가 없어요.\n안내를 끝까지 받은 뒤 '안내 기록에 저장'을 누르면 여기에 남아요.",
        style: AppText.body,
      ),
    );
  }
}

/// 원본 미저장 안내 (Figma "Storage note"). 기록에 이미지 칸이 없는 것과 같은 말 (검토 결론 6장).
class _StorageNote extends StatelessWidget {
  const _StorageNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.tileGallery,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Text(
        '✓  원본 이미지는 저장하지 않아요.\n분석 결과와 사용 방법만 기기에 남겨요.',
        style: AppText.body.copyWith(
          color: AppColors.tileGalleryIcon,
          height: 1.45,
        ),
      ),
    );
  }
}

/// 입력 방식 이름 (홈 입력 칸의 이름과 같게: Figma 기록 줄 "카메라 촬영 · …")
String _inputLabel(InputKind k) => switch (k) {
  InputKind.camera => '카메라 촬영',
  InputKind.gallery => '갤러리 선택',
};

/// "11월 20일 10:05" (외부 패키지 없이. 협업규격 3.6)
String _when(DateTime t) =>
    '${t.month}월 ${t.day}일 ${t.hour}:${t.minute.toString().padLeft(2, '0')}';

/// 관문이 허용할 때만 눌리는 버튼 동작 (홈 화면과 같은 함수. 공용으로 빼면 import 규칙을 바꿔야 해서 둘 다 둔다)
VoidCallback? _on(GuideFlow flow, ActionId id, [Object? arg]) =>
    flow.allows(id) ? () => flow.dispatch(id, arg) : null;

/// 줄 안·확인창 안의 글자 버튼. 앱 테마의 글자 버튼은 가로를 꽉 채우게(52 높이, 폭 무한) 되어 있어
/// 한 줄에 다른 것과 나란히 두면 크기를 정할 수 없다 → 여기서만 작게 (터치 영역은 48 유지).
final _smallButton = TextButton.styleFrom(minimumSize: const Size(64, 48));
