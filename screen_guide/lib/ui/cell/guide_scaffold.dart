import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Figma 공통 틀: 툴바("‹  제목", 높이 60) + 본문(세로, 간격 16) + 하단 버튼 영역(위 여백 16, 간격 10).
/// 좌우 여백 24. 상태 표시줄·홈 표시줄은 실제 기기 것을 쓴다.
class GuideScaffold extends StatelessWidget {
  const GuideScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.footer = const [],
    this.scroll = true,
    this.bottom,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget> body;
  final List<Widget> footer;
  final bool scroll;

  /// 하단 탭처럼 footer 대신 쓰는 영역
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < body.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.section),
          body[i],
        ],
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screenH,
            0,
            AppSpace.screenH,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    if (onBack != null)
                      InkWell(
                        onTap: onBack,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(0, 8, 20, 8),
                          child: Text(
                            '‹',
                            style: TextStyle(
                              fontSize: 26,
                              color: AppColors.textStatus,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        title,
                        style: AppText.toolbar,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: scroll ? SingleChildScrollView(child: content) : content,
              ),
              if (footer.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpace.section,
                    bottom: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < footer.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        footer[i],
                      ],
                    ],
                  ),
                ),
              ?bottom,
            ],
          ),
        ),
      ),
    );
  }
}

/// 주 버튼 (Figma "Action / …" 인디고, 높이 52, 모서리 16). [onPressed]가 null이면 비활성(Gate가 막음).
class PrimaryAction extends StatelessWidget {
  const PrimaryAction(this.label, {super.key, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      FilledButton(onPressed: onPressed, child: Text(label));
}

/// 보조 버튼 (#EEF0F7 배경, #49536A 글자)
class SecondaryAction extends StatelessWidget {
  const SecondaryAction(this.label, {super.key, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: onPressed, child: Text(label));
}

/// 화면 큰 제목 + 보조 설명 (Figma Body 첫 두 줄)
class ScreenHeading extends StatelessWidget {
  const ScreenHeading(this.title, this.subtitle, {super.key, this.size = 22});
  final String title;
  final String subtitle;
  final double size;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppText.headline.copyWith(fontSize: size)),
      const SizedBox(height: 6),
      Text(subtitle, style: AppText.caption),
    ],
  );
}

/// 흰 카드 (모서리 22)
class WhiteCard extends StatelessWidget {
  const WhiteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = AppColors.surface,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: child,
  );
}
