import 'dart:io';

import 'package:flutter/material.dart';

import 'package:screen_guide/shared/contracts/analysis.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

/// 이미지 파일 위에 상자를 그리는 셀. 상자 좌표는 원본 이미지 픽셀 기준이라 표시 크기에 맞게 비율로 바꾼다.
/// 이미지 크기([imageWidth]·[imageHeight])는 분석 응답의 imageSize를 넘긴다. 분석 전이면 비워 두고 사진만 그린다.
/// (좌표 변환을 shared/의 순수 함수로 빼는 일은 협업규격_최종 4.2 4번에서 한다.)
class ScreenImage extends StatelessWidget {
  const ScreenImage({
    super.key,
    required this.path,
    this.imageWidth,
    this.imageHeight,
    this.elements = const [],
    this.target,
    this.height = 350,
    this.dimOthers = false,
  });

  /// 앱 복사본의 파일 경로 (PickedImage.path)
  final String path;
  final int? imageWidth, imageHeight;

  /// 인식한 요소 (얇은 테두리)
  final List<UiElement> elements;

  /// 목표 UI (인디고 굵은 테두리)
  final Box? target;
  final double height;

  /// 목표 밖을 어둡게 (단계 안내 화면)
  final bool dimOthers;

  @override
  Widget build(BuildContext context) {
    final w = imageWidth, h = imageHeight;
    final image = Image.file(
      File(path),
      fit: w == null || h == null ? BoxFit.contain : BoxFit.fill,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: AppColors.surface,
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
    if (w == null || h == null) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        clipBehavior: Clip.antiAlias,
        child: image,
      );
    }
    final aspect = w / h;
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
              final sx = c.maxWidth / w;
              final sy = c.maxHeight / h;
              Rect map(Box b) => Rect.fromLTRB(
                b.left * sx,
                b.top * sy,
                b.right * sx,
                b.bottom * sy,
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  image,
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
