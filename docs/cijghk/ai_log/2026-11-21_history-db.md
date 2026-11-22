# HistoryRepository 로컬 DB — 2026-11-21

브랜치: `feat/history-db` (로컬, 아직 올리지 않음) · 도구: Claude Code (Opus 5.5)
기준: `협업규격_최종` 3.1·3.2·3.4·4.3 #6, `기능별_검토_결론` 6장, `docs/cijghk/데이터_입출력_설계.md` 6-1

## 1. 맡긴 일

`HistoryRepository`의 진짜 구현: 안내 기록을 기기에 저장해 앱을 껐다 켜도 남게 한다(MP3 기준). 원본 이미지·화면에서 읽은 글자·개인정보 후보 값은 저장하지 않는다. 예외를 던지지 않는다. bootstrap의 `history` 줄을 바꾼다.

## 2. 받은 구조

| 파일 | 하는 일 |
|---|---|
| `lib/features/history/data/sqlite_history_repository.dart` | `SqliteHistoryRepository`. 앱 전용 DB 폴더(`getDatabasesPath()`)의 `screen_guide_history.db`, 표 `history_entry` 하나. 처음 쓸 때 열고, 열기에 실패하면 다음 호출 때 다시 연다 |
| `test/features/history/data/sqlite_history_repository_test.dart` | 시험 7건 (PC에서는 `sqflite_common_ffi`로 같은 SQL) |
| `test/ports/history_repository_contract_test.dart` | 기록 공용 시험 `historyRepositoryContract` 4건 |
| `lib/app/bootstrap.dart` | `history` 줄만 `SqliteHistoryRepository()`로 |
| `pubspec.yaml` | `sqflite`, `path` 추가, 시험용 `sqflite_common_ffi`(dev) |

표 열 (HistoryEntry와 1:1): `id`(기본키) · `action_id` · `action_title` · `step_instructions`(JSON 문자열) · `input`(`gallery`/`camera`) · `created_at`(밀리초) · `pii_types`(유형 이름 JSON)

## 3. 하나씩 물어본 것

| 물어본 것 | AI의 설명 |
|---|---|
| 왜 sqflite인가 | 설계 문서 3-2의 [제안]대로. 표 하나라 코드 생성 도구가 필요 없고, Android에서 앱 전용 폴더에 파일로 남아 재시작 후에도 유지된다 |
| 계약의 어느 줄을 지키나 | 규격 3장 공통규칙 1(예외 없음), 3.2 "기록 — 원본 이미지·읽은 글자·후보 값을 담는 칸은 없다", 4.3 #6(공용 시험 통과, 재시작 후 유지, 이미지 경로 칸 없음), 공용 시험의 "같은 id면 덮어쓴다·최근 것부터" |
| 이미지·글자 칸이 정말 없나 | 열 7개가 `HistoryEntry`와 1:1이고, 시험 하나가 `PRAGMA table_info`로 열 이름에 path·image·ocr·masked·label·text가 없는지 확인한다 (골격의 의존 규칙 시험이 `HistoryEntry` 쪽을 확인하는 것과 같은 기준) |
| 실패하면 | 저장·삭제는 조용히 끝나고, 목록은 빈 목록, 한 건은 null. 포트가 `Future<void>`라 흐름은 저장 실패를 모른다 — 설계 문서 9장 5번(지형주와 정할 일) 그대로 |
| 손상된 줄은 | 그 줄만 목록에서 빠지고 나머지는 읽힌다 (시험: 모르는 입력 방식 `live`, 깨진 JSON) |
| 같은 시각의 정렬 | `created_at DESC, id DESC`로 순서가 늘 같다 |
| 앱을 지우면 | DB는 앱 전용 폴더라 함께 지워진다. 클라우드 자동 백업 여부는 `android/` 매니페스트의 `allowBackup` 설정에 달렸다 (아래 5장) |

## 4. 고친 것

- 처음 실행부터 PC에서 `sqflite_common_ffi`가 동작해 시험이 통과했다. 고친 코드 없음.
- `flutter analyze` 0건, 전체 `flutter test` 199건 통과 (main 181 + 기록 11 + 공유 7). Windows에서 실행.

## 4-1. 에뮬레이터 확인

11/21, Android 36 에뮬레이터. 커밋하지 않는 임시 진입점 `tool/history_share_check.dart`(SAVE·LIST·DELETE·SHARE)로 확인했다. 앱을 지우고 새로 설치한 깨끗한 상태에서 시작. 버튼은 내가 직접 눌렀다.

| 확인 | 결과 |
|---|---|
| 시작 | `기록 0건` |
| SAVE 여러 번 | 목록에 최근 것부터 쌓임 |
| 앱을 완전히 종료한 뒤 다시 켜기 | `[시작] 기록 2건` — **저장한 기록이 남음** (MP3 기준) |
| DELETE | 맨 위 기록이 빠짐 |
| 기기의 DB 파일을 꺼내(`run-as … cat`) 열어 봄 | 열 7개(`id, action_id, action_title, step_instructions, input, created_at, pii_types`), 단계 문구 `["메시지 입력 칸을 눌러주세요","보내기를 눌러주세요"]`, `pii_types` `["휴대전화"]` — 이미지·글자 칸 없음 |
| 비정상 종료 | 0건 |

두 기록의 제목이 같았던 것은 같은 초에 두 번 저장해서다(id는 다름).

## 4-2. 올리기 전 점검 (11/22)

- `close()`가 DB 열기에 실패한 상태에서 예외를 낼 수 있었다 → 안에서 잡게 고치고, 열기 실패 시험에 `close()` 확인을 더함. 포트 메서드는 아니지만 "예외 없음"에 맞춤.
- README "남은 일" 표의 내 행에서 기록 DB·Sharer를 완료로 옮김.
- `flutter analyze` 0건, `flutter test` 199건 통과.

## 5. 남은 것

- 흐름 연결: DONE의 "안내 기록에 저장"(`historySave`)과 HISTORY 화면은 지형주(11/27). 저장 실패를 화면에 알릴지 정해야 한다.
- 자동 백업: MP3 앱은 Android 자동 백업을 껐다. 팀 앱 매니페스트(`android/`)의 `allowBackup`은 아직 정하지 않았다 — 기록이 클라우드 백업에 실려도 되는지 팀 확인 필요.
- 동의 시 서버 동기화는 이번 범위 밖 (규격 8장 8번).
