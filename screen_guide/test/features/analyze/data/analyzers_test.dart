import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/analyze/data/fake_analyzer.dart';
import 'package:screen_guide/features/analyze/data/method_channel_analyzer.dart';
import 'package:screen_guide/shared/contracts/analysis.dart';
import 'package:screen_guide/shared/contracts/error_code.dart';

const _guidance = GuidanceFragment(
  packageName: 'com.android.settings',
  screens: [
    ScreenAnchors(screenId: 'demo.settings', anchors: ['배터리', '알림 설정']),
  ],
);

AnalyzeRequest _req({String? selector}) => AnalyzeRequest(
  requestId: 'req-1',
  imagePath: '/tmp/img.jpg',
  guidance: _guidance,
  target: selector == null
      ? null
      : TargetRequest(
          actionId: 'settings.notification',
          stepIndex: 0,
          selector: selector,
        ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FakeAnalyzer 규칙 (협업규격_최종 3.3, 기능별_검토_결론 2-2)', () {
    UiElement el(String label, [int y = 0]) =>
        UiElement(label: label, box: Box(0, y, 100, y + 10));
    GuidanceFragment map(Map<String, List<String>> screens) => GuidanceFragment(
      packageName: '',
      screens: [
        for (final e in screens.entries)
          ScreenAnchors(screenId: e.key, anchors: e.value),
      ],
    );

    test('A: 한 줄이 앵커 두 개로 세어지지 않는다', () {
      final g = map({
        'a.home': ['설정', '알림 설정'],
      });
      expect(FakeAnalyzer.identify([el('알림 설정')], g), isNull);
      expect(FakeAnalyzer.identify([el('설정'), el('알림 설정', 20)], g), 'a.home');
    });

    test('B: 가장 많이 맞은 화면, 같은 수면 식별하지 않는다', () {
      final els = [el('홈'), el('검색', 10), el('주문', 20)];
      expect(
        FakeAnalyzer.identify(
          els,
          map({
            'a.one': ['홈', '검색'],
            'a.two': ['홈', '검색', '주문'],
          }),
        ),
        'a.two',
      );
      expect(
        FakeAnalyzer.identify(
          els,
          map({
            'a.one': ['홈', '검색'],
            'a.two': ['검색', '주문'],
          }),
        ),
        isNull,
      );
    });

    test('C: 같은 글자가 둘 이상이면 대상을 고르지 않는다', () {
      expect(
        FakeAnalyzer.findTarget([el('보내기'), el('보내기', 20)], '보내기'),
        isNull,
      );
      expect(
        FakeAnalyzer.findTarget([el('보내기')], '보내기')!.match,
        MatchKind.exact,
      );
      expect(
        FakeAnalyzer.findTarget([el('보냬기')], '보내기')!.match,
        MatchKind.fuzzy,
      );
      expect(
        FakeAnalyzer.findTarget([el('앱')], '압'),
        isNull,
        reason: '한 글자는 오인식 허용 안 함',
      );
    });

    test('C: 정확 일치가 둘이면 한 글자 차이 요소가 있어도 고르지 않는다 (Kotlin RulesTest와 같은 경우)', () {
      expect(
        FakeAnalyzer.findTarget([
          el('보내기'),
          el('보내기', 20),
          el('보냬기', 40),
        ], '보내기'),
        isNull,
      );
    });

    test('샘플 정답의 개인정보 유형은 9개 값 중 하나', () async {
      final r = await FakeAnalyzer(delay: Duration.zero).analyze(
        AnalyzeRequest(
          requestId: 'p',
          imagePath: 'x/sample_chat.png',
          guidance: _guidance,
        ),
      );
      expect(r.pii, isNotEmpty);
      for (final p in r.pii) {
        expect(piiTypes, contains(p.type));
      }
    });
  });

  group('FakeAnalyzer', () {
    final fake = FakeAnalyzer(delay: Duration.zero);

    test('requestId를 돌려주고 설정 화면으로 식별한다', () async {
      final r = await fake.analyze(_req());
      expect(r.requestId, 'req-1');
      expect(r.ok, isTrue);
      expect(r.screenId, 'demo.settings');
      expect(r.target, isNull, reason: 'target 없는 요청');
    });

    test('selector가 있으면 대상을 찾는다', () async {
      final r = await fake.analyze(_req(selector: '알림 설정'));
      expect(r.target!.label, '알림 설정');
      expect(r.target!.match, MatchKind.exact);
    });

    test('없는 selector면 target이 null (NO_TARGET)', () async {
      final r = await fake.analyze(_req(selector: '결제'));
      expect(r.target, isNull);
    });

    test('개인정보 후보의 elementIndex는 elements 범위 안이다', () async {
      final r = await fake.analyze(_req());
      for (final p in r.pii) {
        expect(p.elementIndex, inInclusiveRange(0, r.elements.length - 1));
      }
    });

    test('요소는 위→아래·왼→오른쪽 순서이고 빈 라벨이 없다 (설계 10장 OCR → UI 요소)', () async {
      final r = await fake.analyze(_req());
      for (var i = 1; i < r.elements.length; i++) {
        final a = r.elements[i - 1].box, b = r.elements[i].box;
        expect(
          a.top < b.top || (a.top == b.top && a.left <= b.left),
          isTrue,
          reason: '${r.elements[i - 1].label} → ${r.elements[i].label}',
        );
      }
      expect(r.elements.every((e) => e.label.trim().isNotEmpty), isTrue);
    });

    test('failWith로 오류를 낸다', () async {
      final r = await FakeAnalyzer(
        delay: Duration.zero,
        failWith: ErrorCode.imageReadFailed,
      ).analyze(_req());
      expect(r.ok, isFalse);
      expect(r.errorCode, ErrorCode.imageReadFailed);
    });
  });

  group('MethodChannelAnalyzer', () {
    const channel = MethodChannel(MethodChannelAnalyzer.channelName);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('요청 JSON을 그대로 보내고 응답을 읽는다', () async {
      MethodCall? sent;
      messenger.setMockMethodCallHandler(channel, (call) async {
        sent = call;
        return {
          'requestId': 'req-1',
          'status': 'ok',
          'errorCode': null,
          'imageSize': {'w': 1080, 'h': 2340},
          'screenId': 'settings',
          'elements': [
            {
              'label': '알림 설정',
              'box': [174, 1029, 341, 1070],
            },
          ],
          'target': {
            'label': '알림 설정',
            'box': [174, 1029, 341, 1070],
            'match': 'fuzzy',
          },
          'pii': [],
          'piiEngine': {'regex': 'ok', 'mlkit': 'failed'},
          'timingMs': {'ocr': 900, 'total': 950},
        };
      });

      final r = await MethodChannelAnalyzer().analyze(_req(selector: '알림 설정'));

      expect(sent!.method, 'analyze');
      final args = Map<String, dynamic>.from(sent!.arguments as Map);
      expect(args['requestId'], 'req-1');
      expect(args['imagePath'], '/tmp/img.jpg');
      expect((args['target'] as Map)['selector'], '알림 설정');
      expect(r.ok, isTrue);
      expect(r.target!.match, MatchKind.fuzzy);
      expect(r.piiEngine!.mlkit, EngineStatus.failed);
    });

    test('계약과 다른 형식의 응답(예: 시험 앱 형식)은 ANALYSIS_FAILED로 받는다', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return {'imageWidth': 1080, 'imageHeight': 2340, 'elements': []};
      });
      final r = await MethodChannelAnalyzer().analyze(_req());
      expect(r.ok, isFalse);
      expect(r.errorCode, ErrorCode.analysisFailed);
    });

    test('안전망: 채널이 PlatformException을 던지면 오류 결과로 바꾼다 (Kotlin은 실패도 result.success 응답 본문으로 보낸다)', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'image_read_failed');
      });
      final r = await MethodChannelAnalyzer().analyze(_req());
      expect(r.ok, isFalse);
      expect(r.requestId, 'req-1');
      expect(r.errorCode, ErrorCode.imageReadFailed);
    });
  });
}
