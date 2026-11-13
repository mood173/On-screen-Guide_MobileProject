# 최종 · 기능 맵 스키마 v1 + AssetGuidanceRepository

2026-11-13 · 최정혁 · PR #3 (`feat/camera-input`)
작업 기록: `ai_log/2026-11-13_feature-map.md` · 설계: `데이터_입출력_설계.md` 5장

## 하는 일

앱이 안내에 쓰는 **기능 맵**(앱별 화면 앵커, 기능, 단계 문구)의 **파일 형식을 정하고**, 앱에 든 JSON 맵을 읽어 흐름에 맵 조각·기능 목록·revision을 준다. 맵은 DB 대신 앱에 든 JSON으로 둔다(일정_현실검토 3-2 [제안], 11/13 팀 확인 대상).

## 쓰는 법

| 항목 | 내용 |
|---|---|
| 형식 | `assets/feature_maps/schema_v1.json` (JSON Schema) |
| 지금 맵 | `assets/feature_maps/sample_v1.json` — **체험용 맵(`DemoGuidance`)과 같은 내용** (시험으로 확인). 앱 동작은 바뀌지 않음 |
| 포트 | `GuidanceRepository.fragment()`, `actionsFor(screenId)`, `activeRevision()` |
| 구현 | `lib/features/guidance_map/data/asset_guidance_repository.dart` — `AssetGuidanceRepository`, 읽기·규칙 확인은 `feature_map.dart` |
| 조립 | `app/bootstrap.dart`: `guidance: AssetGuidanceRepository()` |

## 맵 파일 규칙 (협업규격_최종 3.2)

| 규칙 | 어기면 |
|---|---|
| `schemaVersion` 1, `revision` 있음, 앱 1개 이상 | 맵 전체 거부 |
| 화면 ID `앱.화면`, 맵 전체에서 유일, 앵커 2개 이상·서로 포함 금지 | 〃 |
| 기능 ID `영역.동작`, 유일, 단계 1~5개 | 〃 |
| 단계의 화면이 맵에 있음, 선택자 2자 이상, 안내 문구 있음 | 〃 |
| 시작 화면 = 첫 단계의 화면 (파일에 따로 적지 않음) | — |

맵 조각의 `packageName`은 앱이 하나면 그 이름, 여럿이면 빈 문자열. 맵이 깨지면 예외 없이 **빈 맵**(→ 분석 `UNKNOWN_SCREEN` → "다시 촬영해 주세요")으로 답하고 이유를 `loadError`에 남긴다. 파일은 처음 쓸 때 한 번만 읽는다.

## 확인

- 시험: 단위 28건(앱 맵 파일 확인, 읽기·거부 규칙 21가지, 저장소 동작) + 맵 공용 시험 6건.
- Android 36 에뮬레이터: 앱 번들의 맵을 읽음 — `revision=2026-11-13.1`, 화면 2개, 기능 3개, `loadError=null`.

## 실제 앱 맵을 넣을 때 (11/27, 내용은 강민준)

1. `schema_v1.json` 형식으로 맵 JSON을 만든다 (새 파일이면 `pubspec.yaml` 에셋과 `AssetGuidanceRepository.defaultAsset`을 바꾼다).
2. `flutter test test/ports/guidance_repository_contract_test.dart test/features/guidance_map`으로 규칙을 확인한다.
3. "체험용 맵과 같다" 시험은 지우고, 가짜 분석기 샘플 정답·계약 예시 파일과의 관계를 정한다.

`MapUpdater`(Firebase 갱신)는 만들지 않았다 (가짜 그대로, 제외 [제안]).
