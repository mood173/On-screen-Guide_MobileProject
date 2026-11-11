import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/shared/contracts/analysis.dart';
import 'package:screen_guide/shared/contracts/error_code.dart';

// contract_fixtures/analyze/ 의 공용 예시 파일을 읽는다. Kotlin(팀원 1) JUnit도 같은 파일을 쓴다.
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
      ok.ok && ok.screenId == 'settings' && ok.target!.match == MatchKind.exact,
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
