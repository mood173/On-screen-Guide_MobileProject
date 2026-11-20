import 'dart:ui';

import 'package:screen_guide/shared/contracts/analysis.dart';

/// 좌표 변환: 원본 이미지 픽셀 기준 상자([box]) → 화면에 그린 이미지 안의 사각형.
///
/// 분석기는 상자를 원본 사진([image] 크기) 기준으로 준다. 화면에는 사진이 [view] 크기로
/// 줄거나 늘어서 그려지므로, 가로·세로 비율을 각각 곱해 같은 자리를 찾는다.
/// (시스템설계 3-9·374줄: 포트가 아닌 shared/의 순수 함수, 지형주)
///
/// 원본 크기가 0 이하이면 비율을 정할 수 없으므로 빈 사각형([Rect.zero])을 돌려준다.
Rect mapBox(Box box, {required Size image, required Size view}) {
  if (image.width <= 0 || image.height <= 0) return Rect.zero;
  final sx = view.width / image.width;
  final sy = view.height / image.height;
  return Rect.fromLTRB(
    box.left * sx,
    box.top * sy,
    box.right * sx,
    box.bottom * sy,
  );
}
