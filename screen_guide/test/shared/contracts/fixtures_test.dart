import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/guidance_map/data/demo_guidance.dart';
import 'package:screen_guide/shared/contracts/analysis.dart';
import 'package:screen_guide/shared/contracts/error_code.dart';

// contract_fixtures/analyze/ 의 공용 예시 파일을 읽는다. Kotlin(강민준) JUnit도 같은 파일을 쓴다.
Map<String, dynamic> _load(String name) =>
    jsonDecode(File('contract_fixtures/analyze/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('요청 예시는 DTO로 읽고 다시 써도 같다', () {
    for (final name in ['request_first.json', 'request_step.json']) {
      final json = _load(name);
      expect(AnalyzeRequest.fromJson(json).toJson(), json, reason: name);
    }
    expect(AnalyzeRequest.fromJson(_load('request_first.json')).target, isNull);
    expect(
      AnalyzeRequest.fromJson(_load('request_step.json')).target!.selector,
      '알림 설정',
    );
  });

  test('성공 응답 예시는 DTO로 읽고 다시 써도 같다', () {
    for (final name in [
      'response_ok.json',
      'response_pii.json',
      'response_unknown_screen.json',
    ]) {
      final json = _load(name);
      expect(AnalysisResult.fromJson(json).toJson(), json, reason: name);
    }
  });

  test('각 응답 예시가 흐름에서 뜻하는 것', () {
    final ok = AnalysisResult.fromJson(_load('response_ok.json'));
    expect(
      ok.ok &&
          ok.screenId == 'demo.settings' &&
          ok.target!.match == MatchKind.exact,
      isTrue,
    );

    final pii = AnalysisResult.fromJson(_load('response_pii.json'));
    expect(pii.pii.single.elementIndex, lessThan(pii.elements.length));
    expect(
      pii.piiEngine!.mlkit,
      EngineStatus.failed,
      reason: '모델이 없어도 정규식 결과로 진행',
    );

    final unknown = AnalysisResult.fromJson(
      _load('response_unknown_screen.json'),
    );
    expect(
      unknown.ok && unknown.screenId == null,
      isTrue,
      reason: '→ E(UNKNOWN_SCREEN)',
    );

    final err = AnalysisResult.fromJson(_load('response_error.json'));
    expect(err.ok, isFalse);
    expect(err.errorCode, ErrorCode.imageReadFailed);
  });

  test('예시 값이 협업규격_최종 3.2·3.3 규칙을 따른다', () {
    // 요청의 맵 조각 = 체험용 기능 맵 (가짜 분석기·Kotlin JUnit이 같은 맵으로 식별)
    for (final name in ['request_first.json', 'request_step.json']) {
      expect(
        _load(name)['guidance'],
        DemoGuidance.fragment.toJson(),
        reason: name,
      );
    }
    for (final name in [
      'response_ok.json',
      'response_pii.json',
      'response_unknown_screen.json',
      'response_error.json',
    ]) {
      final r = AnalysisResult.fromJson(_load(name));
      for (final p in r.pii) {
        expect(piiTypes, contains(p.type), reason: '$name: 유형 9개 중 하나');
      }
      final code = _load(name)['errorCode'];
      if (code != null) {
        expect(code, (code as String).toUpperCase(), reason: '오류 코드는 대문자');
      }
    }
  });

  test('모든 예시 파일이 시험 대상에 들어 있다', () {
    final files = Directory('contract_fixtures/analyze')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.json'))
        .toSet();
    expect(files, {
      'request_first.json',
      'request_step.json',
      'response_ok.json',
      'response_pii.json',
      'response_unknown_screen.json',
      'response_error.json',
    });
  });
}
