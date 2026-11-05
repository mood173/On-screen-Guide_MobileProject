import 'package:flutter/services.dart';

import '../contract/analysis.dart';
import '../core/error_code.dart';
import '../domain/screen_analyzer.dart';

/// 실제 Kotlin 분석 모듈과 연결하는 구현체.
///
/// 요청은 [AnalyzeRequest.toJson] 맵을 그대로 넘기고, 응답 맵을 [AnalysisResult.fromJson]으로 읽는다.
/// Kotlin이 result.error(code)로 실패를 알리면 같은 모양의 오류 결과로 바꾼다.
class MethodChannelAnalyzer implements ScreenAnalyzer {
  MethodChannelAnalyzer({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'screen_guide/analyze';
  static const methodName = 'analyze';

  final MethodChannel _channel;

  @override
  Future<AnalysisResult> analyze(AnalyzeRequest request) async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        methodName,
        request.toJson(),
      );
      if (raw == null) {
        return AnalysisResult.error(request.requestId, ErrorCode.analysisFailed);
      }
      return AnalysisResult.fromJson(Map<String, dynamic>.from(raw));
    } on PlatformException catch (e) {
      return AnalysisResult.error(request.requestId, ErrorCode.fromWire(e.code));
    } on MissingPluginException {
      return AnalysisResult.error(request.requestId, ErrorCode.analysisFailed);
    } on TypeError {
      // 응답이 계약 형식과 다름 (필드 누락·타입 불일치). 화면은 일반 분석 실패로 다룬다.
      return AnalysisResult.error(request.requestId, ErrorCode.analysisFailed);
    } on ArgumentError {
      // match·regex 등 enum 값이 계약에 없는 문자열
      return AnalysisResult.error(request.requestId, ErrorCode.analysisFailed);
    }
  }
}
