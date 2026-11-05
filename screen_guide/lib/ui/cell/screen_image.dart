import 'package:flutter/material.dart';

import '../../contract/analysis.dart';
import '../theme/app_tokens.dart';

/// 이미지 위에 상자를 그리는 셀. 상자 좌표는 원본 이미지 픽셀 기준이라 표시 크기에 맞게 비율로 바꾼다
/// (설계 5장 좌표: CoordinateMapper 역할. 데이터 담당이 CoordinateMapper를 만들면 그것으로 교체).
class ScreenImage extends StatelessWidget {
  const ScreenImage({
    super.key,
    required this.asset,
    required this.imageWidth,
    required this.imageHeight,
    this.elements = const [],
    this.target,
    this.height = 350,
    this.dimOthers = false,
  });

  final String asset;
  final int imageWidth, imageHeight;

  /// 인식한 요소 (얇은 테두리)
  final List<UiElement> elements;

  /// 목표 UI (인디고 굵은 테두리)
  final Box? target;
  final double height;

  /// 목표 밖을 어둡게 (단계 안내 화면)
  final bool dimOthers;

  @override
  Widget build(BuildContext context) {
    final aspect = imageWidth / imageHeight;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      alignment: Alignment.center,
      child: AspectRatio(
        aspectRatio: aspect,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, c) {
              final sx = c.maxWidth / imageWidth;
              final sy = c.maxHeight / imageHeight;
              Rect map(Box b) => Rect.fromLTRB(
                b.left * sx,
                b.top * sy,
                b.right * sx,
                b.bottom * sy,
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(asset, fit: BoxFit.fill),
                  if (dimOthers && target != null)
                    CustomPaint(painter: _DimPainter(map(target!).inflate(4))),
                  for (final e in elements)
                    Positioned.fromRect(
                      rect: map(e.box).inflate(1),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  if (target != null)
                    Positioned.fromRect(
                      rect: map(target!).inflate(4),
                      child: DecoratedBox(
                        key: const ValueKey('target-box'),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.target,
                            width: AppSpace.targetStroke,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DimPainter extends CustomPainter {
  _DimPainter(this.hole);
  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(6)));
    canvas.drawPath(path, Paint()..color = const Color(0x66182338));
  }

  @override
  bool shouldRepaint(_DimPainter old) => old.hole != hole;
}
