import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/guidance_map/data/asset_guidance_repository.dart';
import 'package:screen_guide/features/guidance_map/data/demo_guidance.dart';
import 'package:screen_guide/features/guidance_map/data/feature_map.dart';

// 기능 맵 파일(schema v1) 읽기·거부 규칙과 AssetGuidanceRepository.

const _mapFile = 'assets/feature_maps/sample_v1.json';
const _schemaFile = 'assets/feature_maps/schema_v1.json';

String _sample() => File(_mapFile).readAsStringSync();

/// 올바른 최소 맵. 각 시험이 한 군데만 망가뜨린다.
/// JSON 왕복으로 만들어, 실제로 읽는 맵처럼 모든 목록·객체가 dynamic이 되게 한다.
Map<String, dynamic> _valid() =>
    jsonDecode(jsonEncode(_validLiteral)) as Map<String, dynamic>;

const _validLiteral = {
  'schemaVersion': 1,
  'revision': 'r1',
  'apps': [
    {
      'packageName': 'com.example',
      'screens': [
        {
          'screenId': 'app.home',
          'anchors': ['홈', '검색'],
        },
        {
          'screenId': 'app.menu',
          'anchors': ['메뉴', '설정 열기'],
        },
      ],
      'actions': [
        {
          'actionId': 'menu.open',
          'title': '메뉴 열기',
          'description': '',
          'steps': [
            {
              'screenId': 'app.home',
              'selector': '메뉴',
              'instruction': '메뉴를 누르세요',
              'result': '',
            },
            {
              'screenId': 'app.menu',
              'selector': '설정 열기',
              'instruction': '설정 열기를 누르세요',
              'result': '',
            },
          ],
        },
      ],
    },
  ],
};

Map<String, dynamic> _app(Map<String, dynamic> m) =>
    (m['apps'] as List).first as Map<String, dynamic>;
Map<String, dynamic> _action(Map<String, dynamic> m) =>
    (_app(m)['actions'] as List).first as Map<String, dynamic>;
Map<String, dynamic> _screen(Map<String, dynamic> m) =>
    (_app(m)['screens'] as List).first as Map<String, dynamic>;

void _rejects(String why, void Function(Map<String, dynamic> m) breakIt) {
  test('거부: $why', () {
    final m = _valid();
    breakIt(m);
    expect(
      () => FeatureMap.parse(jsonEncode(m)),
      throwsA(isA<FeatureMapException>()),
    );
  });
}

void main() {
  group('앱에 든 맵 파일', () {
    test('규칙을 지키고 읽힌다', () {
      final map = FeatureMap.parse(_sample());
      expect(map.schemaVersion, 1);
      expect(map.revision, isNotEmpty);
      expect(map.actions, isNotEmpty);
    });

    test('지금은 체험용 맵(DemoGuidance)과 내용이 같다 — 가짜 분석기 샘플 정답·계약 예시가 이 맵 기준', () {
      final map = FeatureMap.parse(_sample());
      expect(map.toFragment().toJson(), DemoGuidance.fragment.toJson());
      for (final s in DemoGuidance.fragment.screens) {
        final mine = map.actions
            .where((a) => a.screenId == s.screenId)
            .map((a) => a.toGuideAction())
            .toList();
        final demo = DemoGuidance.forScreen(s.screenId);
        expect(mine.length, demo.length, reason: s.screenId);
        for (var i = 0; i < demo.length; i++) {
          expect(mine[i].actionId, demo[i].actionId);
          expect(mine[i].screenId, demo[i].screenId);
          expect(mine[i].title, demo[i].title);
          expect(mine[i].description, demo[i].description);
          expect(mine[i].steps.length, demo[i].steps.length);
          for (var k = 0; k < demo[i].steps.length; k++) {
            final a = mine[i].steps[k], b = demo[i].steps[k];
            expect(
              [a.screenId, a.selector, a.instruction, a.result],
              [b.screenId, b.selector, b.instruction, b.result],
            );
          }
        }
      }
    });

    test('스키마 문서는 JSON이고, 필수 필드가 읽기 코드와 같다', () {
      final schema = jsonDecode(
        File(_schemaFile).readAsStringSync(),
      ) as Map<String, dynamic>;
      final defs = schema[r'$defs'] as Map<String, dynamic>;
      List<String> req(Map<String, dynamic> o) =>
          (o['required'] as List).cast<String>();
      expect(req(schema), ['schemaVersion', 'revision', 'apps']);
      expect(req(defs['app'] as Map<String, dynamic>), [
        'packageName',
        'screens',
        'actions',
      ]);
      expect(req(defs['screen'] as Map<String, dynamic>), [
        'screenId',
        'anchors',
      ]);
      expect(req(defs['action'] as Map<String, dynamic>), [
        'actionId',
        'title',
        'description',
        'steps',
      ]);
      expect(req(defs['step'] as Map<String, dynamic>), [
        'screenId',
        'selector',
        'instruction',
        'result',
      ]);
    });
  });

  group('읽기 규칙', () {
    test('올바른 최소 맵은 읽히고, 시작 화면은 첫 단계의 화면이다', () {
      final map = FeatureMap.parse(jsonEncode(_valid()));
      expect(map.actions.single.screenId, 'app.home');
      expect(map.toFragment().packageName, 'com.example');
    });

    test('앱이 여럿이면 맵 조각의 packageName은 빈 문자열, 화면은 모두 담는다', () {
      final m = _valid();
      (m['apps'] as List).add({
        'packageName': 'com.other',
        'screens': [
          {
            'screenId': 'other.main',
            'anchors': ['가', '나'],
          },
        ],
        'actions': [],
      });
      final f = FeatureMap.parse(jsonEncode(m)).toFragment();
      expect(f.packageName, '');
      expect(f.screens.map((s) => s.screenId), [
        'app.home',
        'app.menu',
        'other.main',
      ]);
    });

    test('JSON이 아니면 거부', () {
      expect(
        () => FeatureMap.parse('{not json'),
        throwsA(isA<FeatureMapException>()),
      );
    });
    _rejects('schemaVersion이 1이 아님', (m) => m['schemaVersion'] = 2);
    _rejects('revision 없음', (m) => m.remove('revision'));
    _rejects('apps가 비어 있음', (m) => m['apps'] = []);
    _rejects('화면 ID 형식이 앱.화면이 아님', (m) => _screen(m)['screenId'] = 'Home');
    _rejects('앵커가 1개', (m) => _screen(m)['anchors'] = ['홈']);
    _rejects('앵커끼리 포함', (m) => _screen(m)['anchors'] = ['설정', '알림 설정']);
    _rejects('빈 앵커', (m) => _screen(m)['anchors'] = ['홈', ' ']);
    _rejects(
      '화면 ID가 겹침',
      (m) => (_app(m)['screens'] as List)[1]['screenId'] = 'app.home',
    );
    _rejects('기능 ID 형식', (m) => _action(m)['actionId'] = 'open');
    _rejects('기능 ID가 겹침', (m) {
      (_app(m)['actions'] as List).add(jsonDecode(jsonEncode(_action(m))));
    });
    _rejects('단계 0개', (m) => _action(m)['steps'] = []);
    _rejects('단계 6개', (m) {
      final s = (_action(m)['steps'] as List).first;
      _action(m)['steps'] = List.filled(6, s);
    });
    _rejects(
      '단계 화면이 맵에 없음',
      (m) => (_action(m)['steps'] as List).first['screenId'] = 'app.none',
    );
    _rejects(
      '선택자 1글자',
      (m) => (_action(m)['steps'] as List).first['selector'] = '메',
    );
    _rejects(
      '안내 문구 비어 있음',
      (m) => (_action(m)['steps'] as List).first['instruction'] = '',
    );
    _rejects(
      'result 필드 없음',
      (m) => ((_action(m)['steps'] as List).first as Map).remove('result'),
    );
    _rejects(
      'supportLevel이 정해진 값이 아님',
      (m) => _action(m)['supportLevel'] = 'beta',
    );
    _rejects('title 타입이 틀림', (m) => _action(m)['title'] = 3);
  });

  group('AssetGuidanceRepository', () {
    test('맵 파일을 읽어 조각·기능·revision을 준다', () async {
      final repo = AssetGuidanceRepository(source: () async => _sample());
      expect((await repo.fragment()).screens, isNotEmpty);
      expect(await repo.actionsFor('demo.chat'), hasLength(1));
      expect(await repo.activeRevision(), '2026-11-13.1');
      expect(repo.loadError, isNull);
    });

    test('파일은 한 번만 읽는다', () async {
      var reads = 0;
      final repo = AssetGuidanceRepository(
        source: () async {
          reads++;
          return _sample();
        },
      );
      await repo.fragment();
      await repo.actionsFor('demo.settings');
      await repo.activeRevision();
      expect(reads, 1);
    });

    test('깨진 맵이면 예외 없이 빈 맵으로 답하고 이유를 남긴다', () async {
      final repo = AssetGuidanceRepository(
        source: () async => '{"schemaVersion": 1}',
      );
      expect((await repo.fragment()).screens, isEmpty);
      expect(await repo.actionsFor('demo.chat'), isEmpty);
      expect(
        await repo.activeRevision(),
        AssetGuidanceRepository.unavailableRevision,
      );
      expect(repo.loadError, contains('revision'));
    });

    test('파일을 읽지 못해도 예외 없음', () async {
      final repo = AssetGuidanceRepository(
        source: () async => throw const FileSystemException('없음'),
      );
      expect((await repo.fragment()).screens, isEmpty);
      expect(repo.loadError, isNotNull);
    });
  });
}
