# 채널 계약 예시 (screen_guide/analyze)

Flutter(지형주)와 Kotlin(강민준)이 **같은 파일**로 시험한다. 형식은 개발 계약 v1 결정 1, 값의 규칙은 협업규격_최종 3.2·3.3
(화면 ID는 앱.화면, 앵커끼리 포함 금지, 개인정보 유형 9개, 오류 코드 대문자).

| 파일 | 상황 | Flutter가 하는 일 |
|---|---|---|
| request_first.json | 기능 고르기 전 첫 분석 (target 없음) | — |
| request_step.json | 단계 안내 중 대상 찾기 (target 있음) | — |
| response_ok.json | 화면 식별·대상 찾기 성공 | RG 또는 D 화면 |
| response_pii.json | 개인정보 후보 있음, ML Kit 개체 추출 실패(정규식만) | RG에 후보 경고 |
| response_unknown_screen.json | screenId null | E (UNKNOWN_SCREEN) |
| response_error.json | 이미지 읽기 실패 | E (IMAGE_READ_FAILED) |
| response_target_duplicate.json | 단계 안내 중 선택자와 같은 글자가 둘 → target null (추정하지 않음) | E (NO_TARGET) |
| response_target_fuzzy.json | 단계 안내 중 선택자와 한 글자만 다른 요소 하나 → target match fuzzy | D 화면 (대상 강조) |

- Flutter: `test/shared/contracts/fixtures_test.dart`가 모든 파일을 읽어 DTO로 바꾸고 다시 써서 같은지 확인한다.
- Kotlin: JUnit에서 `File("../../contract_fixtures/analyze/request_step.json")`(android/app 기준)을 읽어
  요청을 해석하고, 만든 응답이 response_*.json과 같은 키·타입인지 확인한다.
- 형식을 바꾸면: 협업규격_최종 3장 → 이 파일들 → 양쪽 코드 순서로 고치고 팀 방에 알린다.
