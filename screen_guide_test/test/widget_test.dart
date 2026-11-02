import 'package:flutter_test/flutter_test.dart';
import 'package:screen_guide_test/main.dart';

void main() {
  testWidgets('홈 화면에 시험 버튼이 보인다', (tester) async {
    await tester.pumpWidget(const ScreenGuideTestApp());
    expect(find.text('샘플 1: 설정 화면 분석'), findsOneWidget);
    expect(find.text('갤러리에서 선택'), findsOneWidget);
  });
}
