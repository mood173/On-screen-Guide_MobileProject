import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_guide_test/main.dart';

void main() {
  testWidgets('1단계 입력 선택 화면을 표시한다', (tester) async {
    await tester.pumpWidget(const ScreenGuideTestApp());
    expect(find.text('카메라로 촬영'), findsOneWidget);
    expect(find.text('갤러리에서 선택'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
