/// 오류 코드. (개발 계약 v1 · 결정 1)
///
/// 오류 화면(E·DENY)은 이 코드만 보고 문구와 복구 버튼을 고른다.
enum ErrorCode {
  // Kotlin이 내는 것 (채널 응답의 errorCode 또는 PlatformException.code)
  noPath('NO_PATH'),
  imageReadFailed('IMAGE_READ_FAILED'),
  analysisFailed('ANALYSIS_FAILED'),

  // Flutter 쪽에서만 만드는 것
  unknownScreen('UNKNOWN_SCREEN'),
  noTarget('NO_TARGET'),
  timeout('TIMEOUT'),
  cancelled('CANCELLED'),
  permissionDenied('PERMISSION_DENIED');

  const ErrorCode(this.wire);

  /// 채널·로그에 쓰는 문자열 값.
  final String wire;

  /// 채널에서 받은 문자열을 코드로 바꾼다.
  /// 시험 앱의 소문자 코드(no_path 등)도 받아들이고, 모르는 값은 [analysisFailed]로 본다.
  static ErrorCode fromWire(String? value) {
    final v = value?.toUpperCase();
    for (final c in ErrorCode.values) {
      if (c.wire == v) return c;
    }
    return ErrorCode.analysisFailed;
  }
}
