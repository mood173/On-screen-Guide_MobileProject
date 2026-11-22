// SETTINGS 화면 (협업규격 4.2 5번, 시스템설계 3-9). 흐름 규칙은 guide_flow_test "설정 화면"이 보고,
// 여기서는 화면이 값을 그리고 버튼을 보내는지만 본다. 장식 문구(제목·부제)는 찾지 않는다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/app/app.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/guidance_map/data/asset_guidance_repository.dart';
import 'package:screen_guide/features/guidance_map/data/demo_guidance.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';

import '../../support/test_flow.dart';

/// 정해 둔 revision을 돌려주는 기능 맵
class _FixedRevision extends DemoGuidanceRepository {
  const _FixedRevision(this.value);
  final String value;
  @override
  Future<String> activeRevision() async => value;
}

/// 기기 설정을 연 횟수만 센다
class _CountingCleanup implements InputCleanup {
  var opened = 0;
  @override
  Future<void> openAppSettings() async => opened++;
  @override
  Future<void> clearLeftovers() async {}
  @override
  Future<void> release(PickedImage image) async {}
}

Future<void> _openSettings(
  WidgetTester tester, {
  String revision = 'map-2026-11-20',
  InputCleanup? cleanup,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  final flow = testFlow(guidance: _FixedRevision(revision), cleanup: cleanup);
  await tester.pumpWidget(ScreenGuideApp(flow: flow));
  await tester.tap(find.byKey(const ValueKey('tab-settings')));
  await tester.pumpAndSettle();
  expect(flow.screen, ScreenId.settings);
}

void main() {
  testWidgets('설정 탭 → 설정 화면, 안내 자료 버전이 보이고 설정 탭이 켜져 있다', (tester) async {
    await _openSettings(tester);
    expect(find.text('map-2026-11-20'), findsOneWidget);
    final tab = tester.widget<InkWell>(
      find.byKey(const ValueKey('tab-settings')),
    );
    expect(tab.onTap, isNull, reason: '지금 탭은 눌리지 않는다');
  });

  testWidgets('맵을 못 읽었으면 "확인할 수 없어요" (구현의 unavailable 값과 묶음)', (tester) async {
    // 화면은 data/를 못 보므로 글자를 직접 쓴다 → 최정혁 구현의 값이 바뀌면 이 시험이 실패한다.
    await _openSettings(
      tester,
      revision: AssetGuidanceRepository.unavailableRevision,
    );
    expect(find.text('확인할 수 없어요'), findsOneWidget);
    expect(
      find.text(AssetGuidanceRepository.unavailableRevision),
      findsNothing,
    );
  });

  testWidgets('"카메라·사진 권한 관리" → 기기 설정을 열고 설정 화면에 머문다', (tester) async {
    final cleanup = _CountingCleanup();
    await _openSettings(tester, cleanup: cleanup);
    await tester.tap(find.text('카메라·사진 권한 관리'));
    await tester.pumpAndSettle();
    expect(cleanup.opened, 1);
    expect(find.text('카메라·사진 권한 관리'), findsOneWidget);
  });

  testWidgets('"저장한 안내 기록" → 기록 화면', (tester) async {
    await _openSettings(tester);
    await tester.tap(find.text('저장한 안내 기록'));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 저장한 안내가 없어요'), findsOneWidget);
  });

  testWidgets('동기화 동의 줄은 없다 (시스템설계 8장 "되면 넣는다", 팀 결정 대기)', (tester) async {
    await _openSettings(tester);
    expect(find.textContaining('동기화'), findsNothing);
    expect(find.textContaining('동의'), findsNothing);
  });
}
