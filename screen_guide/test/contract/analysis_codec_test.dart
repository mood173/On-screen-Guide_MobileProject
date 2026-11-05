import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:screen_guide/contract/analysis.dart';
import 'package:screen_guide/core/error_code.dart';

// 개발 계약 v1 문서의 예시 JSON을 그대로 옮겼다. 계약이 바뀌면 이 시험부터 고친다.
const contractRequest = '''
{
  "requestId": "a1b2c3",
  "imagePath": "/data/user/0/.../cache/img.jpg",
  "guidance": {
    "packageName": "com.example.demo",
    "screens": [
      { "screenId": "settings", "anchors": ["설정", "알림 설정", "디스플레이"] },
      { "screenId": "chat", "anchors": ["대화", "보내기"] }
    ]
  },
  "target": { "actionId": "settings.notification", "stepIndex": 0, "selector": "알림 설정" }
}
''';

const contractResponse = '''
{
  "requestId": "a1b2c3",
  "status": "ok",
  "errorCode": null,
  "imageSize": { "w": 1080, "h": 2340 },
  "screenId": "settings",
  "elements": [ { "label": "알림 설정", "box": [174, 1029, 341, 1070] } ],
  "target": { "label": "알림 설정", "box": [174, 1029, 341, 1070], "match": "exact" },
  "pii": [ { "type": "휴대전화", "masked": "010-****-**78", "elementIndex": 7 } ],
  "piiEngine": { "regex": "ok", "mlkit": "ok" },
  "timingMs": { "ocr": 1208, "total": 1264 }
}
''';

void main() {
  group('요청', () {
    test('계약 예시를 읽고 같은 JSON으로 다시 쓴다', () {
      final json = jsonDecode(contractRequest) as Map<String, dynamic>;
      final req = AnalyzeRequest.fromJson(json);

      expect(req.requestId, 'a1b2c3');
      expect(req.guidance.screens, hasLength(2));
      expect(req.guidance.screens.first.anchors, contains('알림 설정'));
      expect(req.target!.actionId, 'settings.notification');
      expect(req.toJson(), json);
    });

    test('target이 없으면 키를 빼고 보낸다 (기능 선택 전 첫 분석)', () {
      const req = AnalyzeRequest(
        requestId: 'r',
        imagePath: '/x.jpg',
        guidance: GuidanceFragment(packageName: 'p', screens: []),
      );
      expect(req.toJson().containsKey('target'), isFalse);
    });
  });

  group('응답', () {
    test('계약 예시를 읽고 같은 JSON으로 다시 쓴다', () {
      final json = jsonDecode(contractResponse) as Map<String, dynamic>;
      final res = AnalysisResult.fromJson(json);

      expect(res.ok, isTrue);
      expect(res.errorCode, isNull);
      expect(res.imageWidth, 1080);
      expect(res.screenId, 'settings');
      expect(res.elements.single.box, const Box(174, 1029, 341, 1070));
      expect(res.target!.match, MatchKind.exact);
      expect(res.pii.single.masked, '010-****-**78');
      expect(res.piiEngine!.mlkit, EngineStatus.ok);
      expect(res.totalMs, 1264);
      expect(res.toJson(), json);
    });

    test('screenId·target이 null이면 null로 읽는다 (UNKNOWN_SCREEN·NO_TARGET 판단 근거)', () {
      final json = jsonDecode(contractResponse) as Map<String, dynamic>
        ..['screenId'] = null
        ..['target'] = null;
      final res = AnalysisResult.fromJson(json);
      expect(res.screenId, isNull);
      expect(res.target, isNull);
    });

    test('오류 응답의 errorCode를 코드로 바꾼다', () {
      final res = AnalysisResult.fromJson({
        'requestId': 'r',
        'status': 'error',
        'errorCode': 'IMAGE_READ_FAILED',
      });
      expect(res.ok, isFalse);
      expect(res.errorCode, ErrorCode.imageReadFailed);
      expect(res.elements, isEmpty);
    });

    test('채널을 거친 Map<Object?, Object?>와 double 숫자도 읽는다', () {
      final Map<Object?, Object?> raw = {
        'requestId': 'r',
        'status': 'ok',
        'imageSize': <Object?, Object?>{'w': 1080.0, 'h': 2340},
        'elements': [
          <Object?, Object?>{'label': '앱', 'box': [1.0, 2, 3, 4]},
        ],
      };
      final res = AnalysisResult.fromJson(Map<String, dynamic>.from(raw));
      expect(res.imageWidth, 1080);
      expect(res.elements.single.box, const Box(1, 2, 3, 4));
    });
  });

  test('ErrorCode는 시험 앱의 소문자 코드도 받고, 모르는 값은 ANALYSIS_FAILED로 본다', () {
    expect(ErrorCode.fromWire('no_path'), ErrorCode.noPath);
    expect(ErrorCode.fromWire('image_read_failed'), ErrorCode.imageReadFailed);
    expect(ErrorCode.fromWire('???'), ErrorCode.analysisFailed);
    expect(ErrorCode.fromWire(null), ErrorCode.analysisFailed);
  });
}
