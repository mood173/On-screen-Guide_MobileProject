import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_guide/contract/analysis.dart';
import 'package:screen_guide/core/error_code.dart';
import 'package:screen_guide/data/fake_analyzer.dart';
import 'package:screen_guide/data/method_channel_analyzer.dart';

const _guidance = GuidanceFragment(
  packageName: 'com.android.settings',
  screens: [ScreenAnchors(screenId: 'settings', anchors: ['설정', '알림 설정'])],
);

AnalyzeRequest _req({String? selector}) => AnalyzeRequest(
      requestId: 'req-1',
      imagePath: '/tmp/img.jpg',
      guidance: _guidance,
      target: selector == null
          ? null
          : TargetRequest(actionId: 'settings.notification', stepIndex: 0, selector: selector),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FakeAnalyzer', () {
    final fake = FakeAnalyzer(delay: Duration.zero);

    test('requestId를 돌려주고 설정 화면으로 식별한다', () async {
      final r = await fake.analyze(_req());
      expect(r.requestId, 'req-1');
      expect(r.ok, isTrue);
      expect(r.screenId, 'settings');
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

    test('failWith로 오류를 낸다', () async {
      final r = await FakeAnalyzer(delay: Duration.zero, failWith: ErrorCode.imageReadFailed)
          .analyze(_req());
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
            {'label': '알림 설정', 'box': [174, 1029, 341, 1070]},
          ],
          'target': {'label': '알림 설정', 'box': [174, 1029, 341, 1070], 'match': 'fuzzy'},
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

    test('Kotlin의 result.error(code)를 오류 결과로 바꾼다', () async {
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
