# wlgud 인수인계

## 담당 범위

팀원 2 지형주 (화면·흐름). 협업규격_최종 4.2.

## 변경·검증 기록

### 2026-11-14 — 단계 설정표 단위 1~5 (브랜치 `feat/stage-table`, 로컬만, push 안 함)

| 커밋 | 내용 |
|---|---|
| 77985ed | 단위 1: `lib/app/stage.dart` — `Stage` 11개(3-0의 10개 + overlay), `screen.stage` |
| 47645d8 | 단위 2: `lib/app/stage_table.dart` — 단계별 허용 버튼(단계 기본 + 장면별) |
| c375c6f | 단위 3: `GuideFlow.allowed`가 표를 봄, `_gate` 삭제, `navHome`은 DONE·E만, `shareConfirmed` 관문 |
| 0e0234f | 단위 3 점검: `shareConfirmed` 읽기 전용 |
| 4fb0f74 | 단위 4: `Shell`·진행 칸(`flow.progress`), 앱 셸 하단 탭, 뒤로는 `_back`이 장면별로 |
| 1bb83ed | 단위 5: `_go`의 단계 훅 `_onExit`·`_onEnter` — 분석 나갈 때 타이머 정지, 복구 들어올 때 실패 단계 기억, 공유 들어올 때 확인 값 지움 |
| a18e423 | 단위 1~5 전체 점검: 서식(`dart format`) 맞춤, 낡은 주석 정리, 기록 갱신 |
| e5bbcfd | 표를 Map → switch(`ruleFor`)로: 단계가 빠지면 컴파일 오류. 단계 설정표는 이것으로 닫음 |

- 검증: `flutter analyze` 0건, `flutter test` 80건 통과 (시작 때 69건, 컴파일러가 대신하는 시험 1건 지움), `dart format` 0건
- 작업 기록: `ai_log/2026-11-14_단계설정표.md` (4-1에 설계 문서 대조 점검 표)

### 2026-11-14 — 입력 연결(협업규격 4.2 4번) 단위 A·B·C (브랜치 `feat/input-connect`, 로컬만)

| 커밋 | 내용 |
|---|---|
| 75f1170 | 단위 A: 입력 결과 → 화면 (`_onPickFailed`), 권한 거부 → DENY, `deniedInput` |
| f7d8a3d | `feat/stage-table`(ruleFor) 받아옴 |
| 75ee976 | 단위 B: 카메라 흐름 H → CP → 촬영 → CR → CA → RC, 다시 찍기·뒤로, CR·CA·RC 화면 재사용, 사진 가져오는 중 연타 잠금 |
| 716e4f3 | 단위 C-1: 권한 안내 화면 DENY(Figma 배치 + 입력별 문구, 설정 열기), Figma 대조로 카메라 세션 CR·RC 문구·제목 맞춤 |
| 7ec86a2 | 단위 C-2: 카메라 권한 설명 화면 CP (Figma 15:113, "카메라 허용", 개인정보 문구 사실대로) |
| 05071e9 | 에뮬레이터 확인: 카메라·갤러리·DENY 화면 눈 확인, CP·DENY 아이콘 상자가 늘어나던 것 고침 |
| cdb382c | ai_log: PR #3과 비교(겹치는 파일 0, 합쳐서 시험 181건), main 되돌림 관계 |

- 검증: analyze 0건, 시험 101건, 서식 0건 / 기록: `ai_log/2026-11-14_입력연결.md`
- **PR #4** (11/16): https://github.com/mood173/On-screen-Guide_MobileProject/pull/4 — `feat/input-connect` → `main`, 커밋 20개, 리뷰어 강민준(mood173)·최정혁(cjh03426), 충돌 없음
- 최종 설명: `최종_단계설정표.md`, `최종_입력연결.md` (11/16, PR 전 — 역할설계 7-1·7-4)
- 11/15 push 준비 점검: main 골격과 맞음, README 갱신, PR #3과 합쳐 시험 181건
- PR은 A·B·C·D가 끝난 뒤 이 브랜치 하나로 (단계 설정표 포함)

- 11/15: 커밋 메시지의 Claude 공동 작성자 줄을 지우면서 두 브랜치의 커밋 번호가 모두 바뀜(코드는 그대로, 위 표는 새 번호). 지우기 전 상태는 로컬 태그 `backup/before-strip-input-connect`, `backup/before-strip-stage-table`

## 남은 확인

- **다음(11/15~16)**: 11/16 점검 카톡 세 줄(매니페스트 권한 선언 없음 알리기)
- 그 뒤: PR #4 리뷰 반영, 단위 D 좌표 변환(담당 확인), 팀 방 공지

- 협업규격 4.2 3번(단계 설정표) 단위 1~5 끝. 다음은 4.2 4번(입력 화면 연결, 결과→화면 변환, 좌표 변환 함수) — 11/20
- 11/27(4.2 7번): 호출 시점 표 시험, E에서 떠날 때 복사본 삭제
- 진행 표시 5칸 셀 그리기 (값은 `flow.progress`)
- 팀 방 공지: ① 등록부 대신 `switch` 유지 ② `navHome`은 문서대로 DONE·E + 앱 셸 탭 ③ 뒤로는 표가 아닌 `_back`이 장면별로 ④ 들어갈 때·나갈 때는 표가 아닌 GuideFlow 훅
- PR에 적을 것: 바꾼 기존 시험 3건 — 홈 버튼 범위(DONE에서 홈으로), 권한 거부 E → DENY(협업규격 3.4), "준비 중" 예시를 카메라 → 기록 탭(카메라 연결됨)
