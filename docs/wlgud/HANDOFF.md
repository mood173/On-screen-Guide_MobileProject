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
| (다음 커밋) | 단위 1~5 전체 점검: 서식(`dart format`) 맞춤, 낡은 주석 정리, 기록 갱신 |

- 검증: `flutter analyze` 0건, `flutter test` 81건 통과 (시작 때 69건), `dart format` 0건
- 작업 기록: `ai_log/2026-11-14_단계설정표.md` (4-1에 설계 문서 대조 점검 표)

## 남은 확인

- 협업규격 4.2 3번(단계 설정표) 단위 1~5 끝. 다음은 4.2 4번(입력 화면 연결, 결과→화면 변환, 좌표 변환 함수) — 11/20
- 11/27(4.2 7번): 호출 시점 표 시험, E에서 떠날 때 복사본 삭제
- 진행 표시 5칸 셀 그리기 (값은 `flow.progress`)
- 팀 방 공지: ① 등록부 대신 `switch` 유지 ② `navHome`은 문서대로 DONE·E + 앱 셸 탭 ③ 뒤로는 표가 아닌 `_back`이 장면별로 ④ 들어갈 때·나갈 때는 표가 아닌 GuideFlow 훅
- PR에 적을 것: 기존 흐름 시험 1건 경로 변경(홈 버튼 범위 변경 때문)
