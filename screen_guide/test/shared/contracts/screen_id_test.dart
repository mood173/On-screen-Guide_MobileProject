import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/shared/contracts/screen_id.dart';
import 'package:screen_guide/shared/theme/app_theme.dart';
import 'package:screen_guide/shared/theme/app_tokens.dart';

void main() {
  test('화면 ID는 설계 문서 7장 목록 전체(33개)이고 코드와 Figma 노드가 겹치지 않는다', () {
    const expected = [
      'H',
      'CP',
      'C',
      'CR',
      'CA',
      'RC',
      'G',
      'GS',
      'GR',
      'GA',
      'RG',
      'D1',
      'D2',
      'D3',
      'D4',
      'D5',
      'DONE',
      'LP',
      'L',
      'LO',
      'LT',
      'LX',
      'LG1',
      'LG2',
      'LG3',
      'LG4',
      'LG5',
      'P',
      'SHARE',
      'HISTORY',
      'SETTINGS',
      'DENY',
      'E',
    ];
    expect(ScreenId.values.map((s) => s.code).toSet(), expected.toSet());
    expect(
      ScreenId.values.map((s) => s.figmaNode).toSet(),
      hasLength(ScreenId.values.length),
    );
    for (final s in ScreenId.values) {
      expect(s.figmaNode, matches(RegExp(r'^\d+:\d+$')), reason: s.code);
    }
  });

  test('fromCode와 figmaUrl', () {
    expect(ScreenId.fromCode('D1'), ScreenId.d1);
    expect(ScreenId.fromCode('X'), isNull);
    expect(ScreenId.h.figmaUrl, endsWith('node-id=14-114'));
  });

  test('테마가 Figma 주 색과 버튼 모양을 쓴다', () {
    final t = AppTheme.light();
    expect(t.colorScheme.primary, AppColors.primary);
    expect(t.scaffoldBackgroundColor, AppColors.background);
    final shape =
        t.filledButtonTheme.style!.shape!.resolve({}) as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(AppRadius.button));
  });
}
