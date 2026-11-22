# 최종 · HistoryRepository (안내 기록 로컬 DB)

2026-11-21 · 최정혁 · 브랜치 `feat/history-db` (로컬, 아직 PR 전)
작업 기록: `../ai_log/2026-11-21_history-db.md` · 설계: `../데이터_입출력_설계.md` 6-1

## 하는 일

사용자가 안내를 마치고 "안내 기록에 저장"을 누르면 그 기록을 **기기 안의 SQLite DB**에 남긴다. 앱을 껐다 켜도 남고, 기록 화면에서 다시 보거나 지울 수 있다. **원본 이미지·화면에서 읽은 글자·개인정보 후보 값은 저장하지 않는다** — 개인정보는 유형 이름만.

## 쓰는 법

| 항목 | 내용 |
|---|---|
| 포트 | `HistoryRepository.save(entry)` · `list()`(최근 것부터) · `get(id)` · `delete(id)` |
| 구현 | `lib/features/history/data/sqlite_history_repository.dart` — `SqliteHistoryRepository` (`sqflite`) |
| 조립 | `app/bootstrap.dart`: `history: SqliteHistoryRepository()` |
| 부르는 곳 (규격 3.4) | 마무리(DONE)의 `historySave`에서만 저장, 기록 화면(HISTORY)의 `historyOpen`·`historyDelete` (지형주) |

## 저장 위치와 표

- 앱 전용 DB 폴더(`getDatabasesPath()`, Android `/data/user/0/<앱>/databases/screen_guide_history.db`). 다른 앱은 읽을 수 없고, 앱을 지우면 함께 지워진다.
- 표 `history_entry` — 열 7개가 `HistoryEntry`와 1:1: `id`, `action_id`, `action_title`, `step_instructions`(JSON), `input`, `created_at`, `pii_types`(유형 이름 JSON). 이미지·글자·가린 값 열은 없다(시험으로 확인).

## 동작

| 메서드 | 결과 |
|---|---|
| `save` | 같은 `id`면 덮어쓴다. 실패해도 예외 없이 끝난다 |
| `list` | `created_at` 최근 것부터(같으면 `id` 순). 손상된 줄은 빠진다. 실패하면 빈 목록 |
| `get` | 없거나 실패하면 null |
| `delete` | 없는 id여도·실패해도 예외 없음 |

DB를 처음 열지 못하면 다음 호출 때 다시 열어 본다.

## 확인

- 시험: 단위 7건(모든 칸 왕복, 열 이름, 파일 DB 닫았다 다시 열기, 열기 실패, 다시 열기, 손상된 줄, 정렬) + 기록 공용 시험 4건. PC에서는 `sqflite_common_ffi`로 같은 SQL을 돌린다.
- Android 36 에뮬레이터: 저장 → **앱을 완전히 종료하고 다시 켜도 기록 유지** → 삭제. 기기의 DB 파일을 꺼내 열어 열 7개와 저장 값(단계 문구·유형 이름만)을 확인. 비정상 종료 0건. **실기기 미확인.**

## 한계와 팀 확인

- 저장 실패를 흐름이 알 방법이 없다(포트가 `Future<void>`). 화면에 알릴지 지형주와 정한다.
- **자동 백업**: 팀 앱 매니페스트에 `allowBackup` 설정이 없어 기본값(켜짐)이다. 기록 DB가 사용자의 클라우드 백업에 실릴 수 있다. MP3 앱처럼 끌지 팀 확인.
- 동의 시 서버 동기화는 만들지 않았다.
