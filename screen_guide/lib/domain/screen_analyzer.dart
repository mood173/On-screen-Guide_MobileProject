import '../contract/analysis.dart';

/// 포트: 이미지 한 장을 분석한다. (개발 계약 v1 · 결정 1)
///
/// 구현체
/// - MethodChannelAnalyzer: 실제 Kotlin 모듈 (채널 screen_guide/analyze)
/// - FakeAnalyzer: 계약 예시 응답을 돌려주는 가짜. 화면·흐름 작업을 Kotlin 없이 시작할 때 쓴다.
///
/// 요청 하나 = 이미지 하나 = 응답 하나. 분석기는 이전 결과를 기억하지 않는다.
/// 실패도 예외 대신 [AnalysisResult.ok] == false 와 errorCode로 돌려준다.
abstract interface class ScreenAnalyzer {
  Future<AnalysisResult> analyze(AnalyzeRequest request);
}
