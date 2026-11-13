# wlgud 인수인계

## 담당 범위

팀원 2 지형주 (화면·흐름). 협업규격_최종 4.2.

## 변경·검증 기록

### 2026-11-14 — 단계 설정표 단위 1~3 (브랜치 `feat/stage-table`, 로컬만, push 안 함)

| 커밋 | 내용 |
|---|---|
| ada903c | 단위 1: `lib/app/stage.dart` — `Stage` 11개(3-0의 10개 + overlay), `screen.stage` |
| 5e981d9 | 단위 2: `lib/app/stage_table.dart` — 단계별 허용 버튼(단계 기본 + 장면별) |
| bc025a4 | 단위 3: `GuideFlow.allowed`가 표를 봄, `_gate` 삭제, `navHome`은 DONE·E만, `shareConfirmed` 관문 |
| 376bab9 | 단위 3 점검: `shareConfirmed` 읽기 전용 |

- 검증: `flutter analyze` 0건, `flutter test` 77건 통과 (시작 때 69건)
- 작업 기록: `ai_log/2026-11-14_단계설정표.md` (4-1에 설계 문서 대조 점검 표)

## 남은 확인

- 단위 4 (화면 틀: 셸·진행 칸·뒤로, 기록·설정 하단 탭) — 11/20
- 단위 5 (들어갈 때·나갈 때 할 일) 틀을 11/20 안에 만들지 결정
- 팀 방 공지: 등록부 대신 `switch` 유지, `navHome`을 문서대로 DONE·E만
- PR에 적을 것: 기존 흐름 시험 1건 경로 변경(홈 버튼 범위 변경 때문)
