# wlgud 인수인계

## 담당 범위

팀원 2 지형주 (화면·흐름). 협업규격_최종 4.2.

## 변경·검증 기록

### 2026-11-14 — 단계 설정표 단위 1~5 (브랜치 `feat/stage-table`, 로컬만, push 안 함)

| 커밋 | 내용 |
|---|---|
| ada903c | 단위 1: `lib/app/stage.dart` — `Stage` 11개(3-0의 10개 + overlay), `screen.stage` |
| 5e981d9 | 단위 2: `lib/app/stage_table.dart` — 단계별 허용 버튼(단계 기본 + 장면별) |
| bc025a4 | 단위 3: `GuideFlow.allowed`가 표를 봄, `_gate` 삭제, `navHome`은 DONE·E만, `shareConfirmed` 관문 |
| 376bab9 | 단위 3 점검: `shareConfirmed` 읽기 전용 |
| b29f5d4 | 단위 4: `Shell`·진행 칸(`flow.progress`), 앱 셸 하단 탭, 뒤로는 `_back`이 장면별로 |
| 44efb47 | 단위 5: `_go`의 단계 훅 `_onExit`·`_onEnter` — 분석 나갈 때 타이머 정지, 복구 들어올 때 실패 단계 기억, 공유 들어올 때 확인 값 지움 |
| b75ee0a | 단위 1~5 전체 점검: 서식(`dart format`) 맞춤, 낡은 주석 정리, 기록 갱신 |
| 이 HANDOFF를 바꾼 커밋 | 표를 Map → switch(`ruleFor`)로: 단계가 빠지면 컴파일 오류. 단계 설정표는 이것으로 닫음 |

- 검증: `flutter analyze` 0건, `flutter test` 80건 통과 (시작 때 69건, 컴파일러가 대신하는 시험 1건 지움), `dart format` 0건
- 작업 기록: `ai_log/2026-11-14_단계설정표.md` (4-1에 설계 문서 대조 점검 표)

### 2026-11-14 — 입력 연결(협업규격 4.2 4번) 단위 A·B (브랜치 `feat/input-connect`, 로컬만)

| 커밋 | 내용 |
|---|---|
| 72133cf | 단위 A: 입력 결과 → 화면 (`_onPickFailed`), 권한 거부 → DENY, `deniedInput` |
| 6129c52 | `feat/stage-table`(ruleFor) 받아옴 |
| 이 HANDOFF를 바꾼 커밋 | 단위 B: 카메라 흐름 H → CP → 촬영 → CR → CA → RC, 다시 찍기·뒤로, CR·CA·RC 화면 재사용, 사진 가져오는 중 연타 잠금 |

- 검증: analyze 0건, 시험 95건, 서식 0건 / 기록: `ai_log/2026-11-14_입력연결.md`
- PR은 A·B·C·D가 끝난 뒤 이 브랜치 하나로 (단계 설정표 포함)

## 남은 확인

- 협업규격 4.2 3번(단계 설정표) 단위 1~5 끝. 다음은 4.2 4번(입력 화면 연결, 결과→화면 변환, 좌표 변환 함수) — 11/20
- 11/27(4.2 7번): 호출 시점 표 시험, E에서 떠날 때 복사본 삭제
- 진행 표시 5칸 셀 그리기 (값은 `flow.progress`)
- 팀 방 공지: ① 등록부 대신 `switch` 유지 ② `navHome`은 문서대로 DONE·E + 앱 셸 탭 ③ 뒤로는 표가 아닌 `_back`이 장면별로 ④ 들어갈 때·나갈 때는 표가 아닌 GuideFlow 훅
- PR에 적을 것: 바꾼 기존 시험 3건 — 홈 버튼 범위(DONE에서 홈으로), 권한 거부 E → DENY(협업규격 3.4), "준비 중" 예시를 카메라 → 기록 탭(카메라 연결됨)
