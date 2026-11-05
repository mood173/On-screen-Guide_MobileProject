import 'package:flutter_test/flutter_test.dart';
import 'package:screen_guide/bootstrap.dart';
import 'package:screen_guide/main.dart';

void main() {
  testWidgets('골격 화면이 가짜 분석기로 예시 요청을 끝까지 처리한다', (tester) async {
    await tester.pumpWidget(ScreenGuideApp(deps: bootstrap(fake: true)));

    expect(find.text('화면길잡이 (골격)'), findsOneWidget);
    await tester.tap(find.text('예시 요청 보내기'));
    await tester.pump();
    expect(find.text('분석 중…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('화면: settings'), findsOneWidget);
    expect(find.textContaining('대상: 알림 설정'), findsOneWidget);
  });
}
