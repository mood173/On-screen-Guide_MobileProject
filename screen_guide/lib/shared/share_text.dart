/// 공유 텍스트 만들기 (협업규격 4.2 7번, 검토 결론 5장 필수 "순수 함수 하나: 기능 제목 + 단계 문구 → 텍스트").
///
/// 받는 것은 글자 두 가지뿐이다: 기능 제목, 단계 문구. 둘 다 기능 맵에 사람이 써 둔 글이다.
/// 분석 결과(화면에서 읽은 글자·개인정보 후보)는 받지 않으므로 공유 글에 섞일 길이 없다.
///
/// SHARE 화면의 미리보기와 실제로 보내는 글이 같은 이 함수를 쓴다 → 보이는 것과 보내는 것이 같다.
/// 구현이 하나뿐인 순수 계산이라 인터페이스 없이 함수로 둔다 (협업규격 2장 규칙 4, coordinate_mapper와 같은 자리).
String buildShareText({required String title, required List<String> steps}) {
  final lines = <String>[
    '$title · 사용 방법',
    for (var i = 0; i < steps.length; i++) '${i + 1}. ${steps[i]}',
    '',
    // 받는 사람이 어디서 온 글인지 알게 하는 고정 문장 (화면 글자가 아님)
    '(화면길잡이로 찾은 사용 방법이에요)',
  ];
  return lines.join('\n');
}
