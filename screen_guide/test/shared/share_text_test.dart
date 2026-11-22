// 공유 텍스트 함수 (협업규격 4.2 7번 "공유 텍스트에 인식 글자·가린 값 없음", 검토 결론 5장 필수).

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/analyze/data/sample_answers.dart';
import 'package:screen_guide/features/guidance_map/data/demo_guidance.dart';
import 'package:screen_guide/shared/share_text.dart';

void main() {
  test('모양: 제목 · 사용 방법, 번호 붙은 단계, 빈 줄, 고정 문장', () {
    expect(
      buildShareText(
        title: '메시지 보내기',
        steps: const ['메시지 입력 칸을 눌러주세요', '보내기를 눌러주세요'],
      ),
      '메시지 보내기 · 사용 방법\n'
      '1. 메시지 입력 칸을 눌러주세요\n'
      '2. 보내기를 눌러주세요\n'
      '\n'
      '(화면길잡이로 찾은 사용 방법이에요)',
    );
  });

  test('단계가 없으면 제목과 고정 문장만', () {
    expect(
      buildShareText(title: '알림 설정 바꾸기', steps: const []),
      '알림 설정 바꾸기 · 사용 방법\n\n(화면길잡이로 찾은 사용 방법이에요)',
    );
  });

  // "인식 글자 없음"을 글자 그대로 쓰면 거짓으로 실패한다: 기능 맵은 화면의 버튼 글자('보내기')를 보고 쓰므로
  // 단계 문구와 화면 글자가 겹치는 게 정상이다. 그래서 막으려는 것(대화 내용·개인정보)을 직접 확인한다 (11/22 해석, ai_log).
  test('대화 샘플: 공유 글에 가린 값, 개인정보가 든 화면 글, 기능 맵에 없는 화면 글이 없다', () {
    const answer = SampleAnswer.chat;
    final action = DemoGuidance.forScreen(answer.screenId).single;
    final text = buildShareText(
      title: action.title,
      steps: [for (final s in action.steps) s.instruction],
    );

    // ① 가린 값
    for (final p in answer.pii) {
      expect(text, isNot(contains(p.masked)), reason: '가린 값 ${p.type}');
    }

    // 기능 맵에 사람이 써 둔 글 전체 (앵커·제목·설명·단계 문구·선택자)
    final mapWords = <String>[
      for (final s in DemoGuidance.fragment.screens) ...s.anchors,
      for (final a in DemoGuidance.actions) ...[
        a.title,
        a.description,
        for (final st in a.steps) ...[st.instruction, st.selector],
      ],
    ].join('\n');

    for (final e in answer.elements) {
      final inMap = mapWords.contains(e.label);
      // ② 개인정보가 든 화면 글 줄 ("사무실 번호는 02-123-4567 입니다" 등)과
      // ③ 기능 맵 어디에도 없는 화면 글은 공유 글에 나오면 안 된다
      if (!inMap) {
        expect(text, isNot(contains(e.label)), reason: '화면 글 "${e.label}"');
      }
    }
    // 시험이 헛돌지 않는지: 막아야 할 화면 글이 실제로 있었다
    expect(
      answer.elements.where((e) => !mapWords.contains(e.label)),
      isNotEmpty,
    );
  });
}
