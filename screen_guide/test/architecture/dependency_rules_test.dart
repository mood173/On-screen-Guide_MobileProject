// 폴더 의존 규칙 검사 (협업규격_최종 2장 "의존 규칙", import 검사 시험 1건).
//
// - 기능 안에서 ui·data는 domain만 본다 (ui는 data를 보지 않는다).
// - 기능끼리는 서로의 domain과 shared/만 본다.
// - shared/는 app/·features/를 보지 않는다.
// - 구현(data)을 import하는 곳은 app/bootstrap.dart뿐이다 (같은 기능 안의 data끼리는 허용).
// - 예외 하나: 화면(ui)은 흐름 입구 app/guide_flow.dart를 본다 (11/11 결정, README).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _import = RegExp(
  r"^import 'package:screen_guide/([^']+)';",
  multiLine: true,
);

/// lib/ 기준 경로 → (구역, 기능, 층)
({String zone, String? feature, String? layer}) _where(String path) {
  final p = path.split('/');
  if (p.first == 'features') {
    return (zone: 'features', feature: p[1], layer: p[2]);
  }
  return (zone: p.length > 1 ? p.first : path, feature: null, layer: null);
}

String? _violation(String from, String to) {
  final a = _where(from), b = _where(to);
  if (a.zone == 'shared' && (b.zone == 'app' || b.zone == 'features')) {
    return 'shared는 app·features를 보지 않는다';
  }
  if (a.zone == 'features') {
    if (b.zone == 'app') {
      final ok = a.layer == 'ui' && to == 'app/guide_flow.dart';
      return ok ? null : '기능은 app을 보지 않는다 (ui → app/guide_flow.dart만 예외)';
    }
    if (b.zone == 'features') {
      if (a.feature == b.feature) {
        if (a.layer == 'ui' && b.layer == 'data') return 'ui는 data를 보지 않는다';
        if (a.layer == 'domain' && b.layer != 'domain') {
          return 'domain은 같은 기능의 domain만 본다';
        }
      } else if (b.layer != 'domain') {
        return '다른 기능은 domain만 본다';
      }
    }
  }
  if (a.zone == 'app' && from != 'app/bootstrap.dart') {
    if (b.zone == 'features' && b.layer == 'data') {
      return '구현(data)은 app/bootstrap.dart만 import한다';
    }
  }
  return null;
}

void main() {
  test('lib/ 의 import가 폴더 의존 규칙을 지킨다', () {
    final bad = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final from = f.path.replaceAll(r'\', '/').substring('lib/'.length);
      for (final m in _import.allMatches(f.readAsStringSync())) {
        final why = _violation(from, m.group(1)!);
        if (why != null) bad.add('$from → ${m.group(1)}  ($why)');
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('규칙 검사기 자체 확인', () {
    expect(
      _violation('app/guide_flow.dart', 'features/history/data/x.dart'),
      isNotNull,
    );
    expect(
      _violation('app/bootstrap.dart', 'features/history/data/x.dart'),
      isNull,
    );
    expect(
      _violation('features/guide/ui/a.dart', 'app/guide_flow.dart'),
      isNull,
    );
    expect(
      _violation('features/guide/ui/a.dart', 'app/bootstrap.dart'),
      isNotNull,
    );
    expect(
      _violation('features/capture/ui/a.dart', 'features/capture/data/b.dart'),
      isNotNull,
    );
    expect(
      _violation(
        'features/analyze/data/a.dart',
        'features/capture/data/b.dart',
      ),
      isNotNull,
    );
    expect(
      _violation(
        'features/history/domain/a.dart',
        'features/capture/domain/b.dart',
      ),
      isNull,
    );
    expect(_violation('shared/cells/a.dart', 'app/guide_flow.dart'), isNotNull);
  });

  test('기록 자료형에 이미지·인식 글자·가린 값 칸이 없다 (기능별_검토_결론 6장, MP3)', () {
    final src = File('lib/features/history/domain/history.dart')
        .readAsStringSync();
    final body = src.substring(
      src.indexOf('class HistoryEntry'),
      src.indexOf('abstract interface class'),
    );
    final fields = RegExp(
      r'^\s+final [\w<>?, ]+ (\w+);',
      multiLine: true,
    ).allMatches(body).map((m) => m.group(1)!.toLowerCase());
    for (final f in fields) {
      for (final bad in ['path', 'image', 'ocr', 'masked', 'label', 'text']) {
        expect(f.contains(bad), isFalse, reason: 'HistoryEntry.$f');
      }
    }
  });
}
