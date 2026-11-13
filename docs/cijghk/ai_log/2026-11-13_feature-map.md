# 기능 맵 스키마 v1 + 메모리 구현 — 2026-11-13

브랜치: `feat/camera-input` (PR #3에 이어서) · 도구: Claude Code (Opus 5.5)
기준: `협업규격_최종` 3.1·3.2(기능 맵 규칙)·4.3 #1, `일정_현실검토` 3-2(맵은 DB 대신 앱에 든 JSON [제안]), `docs/cijghk/데이터_입출력_설계.md` 5장

## 1. 맡긴 일

기능 맵 파일 형식(스키마)을 문서로 정하고, 그 파일을 읽는 `GuidanceRepository` 진짜 구현을 만들어 맵 공용 시험을 통과시킨다. bootstrap의 `guidance` 줄을 바꾼다. 실제 앱 맵 내용(앵커·선택자·문구)은 11/27 강민준 담당이라 이번에는 형식과 읽는 코드만.

## 2. 받은 구조

| 파일 | 하는 일 |
|---|---|
| `assets/feature_maps/schema_v1.json` | 맵 파일 형식 (JSON Schema). 필수 필드·ID 형식·앵커 2개 이상·단계 1~5개 |
| `assets/feature_maps/sample_v1.json` | 지금 쓰는 맵. **체험용 맵(`DemoGuidance`)과 같은 내용** — 가짜 분석기의 샘플 정답과 계약 예시 파일이 이 맵 기준이라 |
| `lib/features/guidance_map/data/feature_map.dart` | 저장 모양(`FeatureMap`·`AppGuide`·`ScreenDef`·`ActionDef`·`StepDef`)과 읽기·규칙 확인. 하나라도 어기면 `FeatureMapException`으로 맵 전체 거부 |
| `lib/features/guidance_map/data/asset_guidance_repository.dart` | `AssetGuidanceRepository`. 처음 쓸 때 한 번 읽어 메모리에 둔다. 깨진 맵이면 예외 없이 빈 맵 |
| `test/features/guidance_map/data/feature_map_test.dart` | 시험 28건 (앱 맵 파일 확인, 읽기·거부 규칙 21가지, 저장소 동작) |
| `test/ports/guidance_repository_contract_test.dart` | 맵 공용 시험 `guidanceRepositoryContract`(6건)에 앱 맵 파일 그대로 |
| `lib/app/bootstrap.dart`, `pubspec.yaml` | `guidance` 줄 교체, 에셋에 맵 파일 등록 |

## 3. 하나씩 물어본 것

| 물어본 것 | AI의 설명 |
|---|---|
| 규격 3.2 규칙을 어디서 확인하나 | 한 항목 안의 규칙(ID 형식, 앵커 2개 이상·서로 포함 금지, 단계 1~5개, 선택자 2자 이상, 안내 문구)은 그 항목을 읽을 때, 전체 규칙(화면·기능 ID 유일, 단계 화면이 맵에 있음)은 다 읽은 뒤 확인한다. JSON Schema로 표현 못 하는 규칙은 읽기 코드와 공용 시험이 맡는다 |
| 기능의 시작 화면을 왜 파일에 적지 않나 | 규격은 "첫 단계의 화면 = 시작 화면"이다. 두 곳에 적으면 어긋날 수 있어서 첫 단계에서 얻는다 |
| 맵 조각의 `packageName`은 | 앱이 하나면 그 이름, 여럿이면 빈 문자열. 스크린샷으로는 앱을 알 수 없어 조각에 모든 앱의 화면을 담는다 (규격 3.3, 8장 5번은 아직 [제안]) |
| 맵이 깨지면 | 예외를 던지지 않고 빈 맵(화면 0개)으로 답한다 → 분석은 `UNKNOWN_SCREEN` → "다시 촬영해 주세요". 이유는 `loadError`에 남긴다. 앱에 든 맵이 깨지는 것은 만들 때의 실수라 시험이 먼저 잡는다 |
| 왜 DB가 아니라 JSON인가 | 대상 앱 1~2개·기능 3개라 DB가 필요 없다 (일정_현실검토 3-2). 11/13 팀 확인 전 [제안]이라 결과에 따라 바꾼다 |
| 바꿔 끼워도 앱 동작이 같은가 | 시험 하나가 JSON 맵의 조각·기능·단계가 체험용 맵과 글자 단위로 같은지 확인한다. 실제 맵으로 바꿀 때 이 시험을 고친다 |

## 4. 고친 것

- 거부 시험 하나가 시험용 맵의 목록 타입 때문에 실패(Dart 리터럴 `List<Map<String, Object>>`에 JSON 항목을 넣으려다 타입 오류) → 시험용 맵을 JSON 왕복으로 만들어 실제 읽는 맵과 같은 모양으로. 읽기 코드 결함이 아니었다.
- lint 3건(`curly_braces`, `prefer_initializing_formals`) 정리.
- `flutter analyze` 0건, `flutter test` 136건 통과 (이 작업 끝 시점).

## 4-1. 에뮬레이터 확인 (11/13, Android 36 에뮬레이터)

갤러리 확인용 임시 진입점(커밋 안 함)의 MAP 버튼으로 앱 안에서 `AssetGuidanceRepository()`를 불렀다: `revision=2026-11-13.1`, 화면 2개, 기능 `settings.notification, settings.display, chat.send`, `error=null`. 앱 번들에 맵 파일이 들어가고 기기에서 읽히는 것을 확인했다.

## 5. 남은 것

- 실제 앱 맵 내용(11/27, 강민준): `sample_v1.json`을 바꾸거나 새 파일을 만들고 `defaultAsset`을 바꾼다. 그때 "체험용 맵과 같다" 시험은 지운다. 가짜 분석기 샘플 정답·계약 예시 파일과의 관계도 같이 정해야 한다.
- 11/13 팀 회의에서 JSON 방식·Firebase 제외가 정해지면 설계 문서를 확정한다.
- `MapUpdater`(Firebase)는 만들지 않았다 (가짜 그대로).
