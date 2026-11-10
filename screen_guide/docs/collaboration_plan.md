# 화면길잡이 협업 틀 · 세부 계획 · 일정

2026-11-10 · 마감 **12/6(일)** · 기능 동결 **12/4(금)**
팀원: 팀원 1 **강민준** (분석·AI) · 팀원 2 **지형주** (화면·흐름) · 팀원 3 **최정혁** (데이터·입출력)

> 이 문서의 목적: 셋이 따로 만든 것을 **마지막에 한 번에 합치다가 터지지 않게**, 맞물리는 곳(연결 지점)을 먼저 코드로 고정하고, 누가 무엇을 언제까지 주고받는지 정한다.

---

## 1. 결합 구조 한눈에 보기

```
              ┌──────────────── 팀원 2 (화면·흐름) ────────────────┐
              │  화면(ui/screen)  →  흐름 관리자(runtime/guide_flow) │
              └───────────────────────────┬────────────────────────┘
                                          │ 포트(인터페이스)로만 부른다
   ┌──────────────┬──────────────┬────────┴─────┬──────────────┬──────────────┐
   │ ScreenAnalyzer│ ImageInput   │GuidanceRepo  │HistoryRepo   │Sharer/MapUpd.│
   │   C1          │   C2         │   C3         │   C4         │  C5 / C6     │
   └──────┬───────┴──────┬───────┴──────┬───────┴──────┬───────┴──────┬───────┘
          │              │              │              │              │
     팀원 1 (Kotlin)   팀원 3          팀원 3         팀원 3         팀원 3
     채널 analyze     image_picker    로컬 DB        로컬 DB        share_plus / Firebase
```

- 화면·흐름은 **포트만** 안다. 진짜인지 가짜인지는 `lib/bootstrap.dart` 한 곳에서 정한다.
- 지금은 모든 포트에 **가짜 구현**이 꽂혀 있어서 앱이 처음부터 끝까지 돈다.
- 각자 진짜 구현을 만들면 **공용 시험 통과 → bootstrap 한 줄 교체 → PR** 순서로 꽂는다.

---

## 2. 연결 지점 상세 (C1~C7)

각 연결 지점마다: 누가 주고 누가 받는지, 어디에 있는지, 어떤 형식인지, 실패하면 어떻게 하는지, 다 됐는지 어떻게 확인하는지.

### C1. 분석 채널 — 팀원 1 → 팀원 2

| 항목 | 내용 |
|---|---|
| 포트 | `lib/domain/screen_analyzer.dart` — `Future<AnalysisResult> analyze(AnalyzeRequest)` |
| 형식 | 채널 `screen_guide/analyze`, 메서드 `analyze`. 요청·응답 JSON = 개발 계약 v1 결정 1 = `lib/contract/analysis.dart` |
| **공용 예시 파일** | `contract_fixtures/analyze/*.json` (요청 2종, 응답 4종). **양쪽이 같은 파일로 시험** |
| Flutter 쪽 (완성) | `MethodChannelAnalyzer`: 요청 맵 그대로 전송, 응답 맵 → DTO. PlatformException·형식 불일치 → 오류 결과(앱이 멈추지 않음) |
| Kotlin 쪽 (팀원 1) | `MainActivity.kt` 인자 `imagePath`·`guidance`·`target` 받기 / `Analyzer.kt` 요청의 맵으로 화면 식별, 응답을 계약 JSON으로 / OCR 줄 로그 제거 |
| 실패 처리 | Kotlin이 내는 코드: `NO_PATH`, `IMAGE_READ_FAILED`, `ANALYSIS_FAILED`. `screenId` null → 흐름이 `UNKNOWN_SCREEN`, `target` null → `NO_TARGET`. ML Kit 개체 추출 실패 → `piiEngine.mlkit: "failed"`로 알리고 정규식 결과로 진행 |
| 지켜야 할 것 | 원본 이미지·OCR 원문 전체·후보 원문은 응답에 넣지 않는다. box는 원본 픽셀 `[l,t,r,b]` |
| 완료 확인 | ① Kotlin JUnit이 `request_step.json`을 읽어 해석하고, 만든 응답이 `response_ok.json`과 같은 키·타입 ② `flutter run --dart-define=FAKE_ANALYZER=false`로 샘플 2장 홈→완료, 테두리 위치가 가짜 때와 같음 |
| 교체 | `bootstrap.dart`: `useFakeAnalyzer` 기본값 `true` → `false` |
| **마감** | **11/20(금)** |

### C2. 사진 가져오기 — 팀원 3 → 팀원 2

| 항목 | 내용 |
|---|---|
| 포트 | `lib/domain/image_input.dart` — `pickFromGallery()`, `takePhoto()`, `release(PickedImage)` |
| 결과 | `PickedImage { status: ok/cancelled/permissionDenied/readFailed, path, input, appOwned }` |
| 지켜야 할 것 | 정지 이미지 1장(C01), `requestFullMetadata: false`, 위치·연락처 권한 요청 금지, **앱이 만든 복사본(appOwned)만 삭제** |
| 흐름의 처리 (팀원 2, 2주차에 구현) | ok → GR(확인) / cancelled → 이전 화면 유지 / permissionDenied → DENY / readFailed → E |
| 지금 | `FakeImageInput` (샘플 이미지를 앱 복사본으로 반환, status를 바꿔 실패 화면 시험 가능) |
| 완료 확인 | 공용 시험 `imageInputShapeContract` + 에뮬레이터: 갤러리 선택·취소·권한 거부, 카메라 촬영 각각 화면 확인 |
| **마감** | **11/20(금)** |

### C3. 기능 맵 — 팀원 3 → 팀원 2 (→ 팀원 1)

| 항목 | 내용 |
|---|---|
| 포트 | `lib/domain/guidance.dart` — `fragment()`, `actionsFor(screenId)`, `activeRevision()` |
| 모델 | `GuideAction { actionId(영역.동작), screenId, title, description, steps[] }`, `GuideStep { selector, instruction, result }` |
| 팀원 1과의 관계 | `fragment()`의 앵커가 분석 요청에 그대로 들어가 Kotlin 화면 식별에 쓰인다. `GuideStep.selector`가 대상 찾기에 쓰인다 → **실제 앱 맵은 팀원 1과 같이 스크린샷으로 검증** |
| 저장 형식 | 기능·개념 정리 9.2 `guidance_maps` (package_name, version 범위, screen_id, screen_anchors, action_id, utterances, selectors, steps, support_level, source…) — 스키마는 팀원 3이 확정 |
| 지금 | `DemoGuidanceRepository` (체험용 3개) |
| 완료 확인 | **공용 시험 `guidanceRepositoryContract` 통과** (화면마다 앵커 2개 이상, 기능 ID 형식·중복 없음, 단계 1개 이상, 모르는 화면은 빈 목록) + 실제 앱 기능 3개 오프라인 안내 |
| **마감** | 스키마·메모리 구현 **11/20**, 로컬 DB + 실제 기능 3개 **11/27** |

### C4. 안내 기록 — 팀원 3 → 팀원 2

| 항목 | 내용 |
|---|---|
| 포트 | `lib/domain/history.dart` — `save`, `list`(최근 순), `get`, `delete` |
| 모델 | `HistoryEntry { id, actionId, actionTitle, stepInstructions, input, createdAt, piiTypes }` — **원본 이미지·OCR 원문·후보 원문 없음** (C03) |
| 흐름 (완성) | DONE "안내 기록에 저장" → `save` → "안내 기록에 저장했어요" |
| 지금 | `InMemoryHistoryRepository` |
| 완료 확인 | 공용 시험 `historyRepositoryContract` 통과 + 앱을 껐다 켜도 HISTORY에 남음 |
| **마감** | **11/27(금)** |

### C5. 공유 — 팀원 3 → 팀원 2

| 항목 | 내용 |
|---|---|
| 포트 | `lib/domain/share_and_update.dart` — `Sharer.shareText(text)` |
| 지켜야 할 것 | **사용 방법 텍스트만** (예: "알림 설정 바꾸기 · 사용 방법 1단계 …"), 원본 이미지 미포함 |
| 흐름 (팀원 2, 2~3주차에 구현) | RG·DONE·HISTORY 어디서 공유하든 **반드시 P(공유 전 확인)를 거친 뒤** SHARE → `shareText`. 후보 0건이어도 P 표시 (NFR-01) |
| 지금 | `FakeSharer` (보낸 텍스트 기억) |
| 완료 확인 | 공유 진입 경로 전수 시험: P 없이 공유되는 경로 0개 |
| **마감** | **11/27(금)** |

### C6. 기능 맵 갱신 (B01/B02) — 팀원 3 → 팀원 2

| 항목 | 내용 |
|---|---|
| 포트 | `MapUpdater.checkForUpdate()` → `MapUpdateResult { upToDate/updated/offline/rejected, revision }` |
| 지켜야 할 것 | 해시·서명·스키마 검증 후 원자 교체. **어떤 실패든 이전 revision 유지, 안내는 계속** |
| 흐름 (팀원 2, 4주차에 구현) | 앱 시작 시 `mapCheck`로 호출, 결과를 막지 않음. SETTINGS에 revision 표시 |
| 지금 | `FakeMapUpdater` (항상 최신) |
| **마감** | **12/2(수)** — 늦으면 이번 제출에서 제외 (가짜 유지) |

### C7. 화면·버튼 계약 — 팀원 2 ↔ 팀 전체

| 항목 | 내용 |
|---|---|
| 버튼 | `lib/core/action_id.dart` (계약 v1 결정 2). 새 버튼 → **계약 문서 먼저** 수정 후 팀 방 공지 |
| 화면 | `lib/core/screen_id.dart` = Figma 프레임 (`docs/figma.md`) |
| 오류 | `lib/core/error_code.dart` — 오류 화면은 코드만 보고 문구를 고른다 |
| 정할 것 | "선택한 이미지 사용"용 ID (지금 `captureGallery` 재사용) |

---

## 3. 파일 소유권 (충돌 막기)

| 영역 | 고치는 사람 | 다른 사람이 고칠 때 |
|---|---|---|
| `android/**` (Kotlin) | 팀원 1 | PR 리뷰 요청 |
| `lib/ui/**`, `lib/runtime/**`, `lib/main.dart` | 팀원 2 | PR 리뷰 요청 |
| `lib/data/**`(분석기 제외), 팀원 3 구현 파일 | 팀원 3 | PR 리뷰 요청 |
| `lib/data/method_channel_analyzer.dart`, `fake_analyzer.dart` | 팀원 2 (팀원 1과 협의) | — |
| **공용**: `lib/core/**`, `lib/contract/**`, `lib/domain/**`(포트), `contract_fixtures/**` | 바꾸기 전 **팀 방 공지 + 계약 문서 먼저** | 세 명 모두 영향 |
| **공용**: `lib/bootstrap.dart` | 각자 **자기 포트 줄만** 교체 | — |
| `test/runtime/**`, `test/widget_test.dart` | 팀원 2 | PR 리뷰 요청 |
| `android/app/src/test/**` (JUnit) | 팀원 1 | PR 리뷰 요청 |
| **공용**: `test/ports/port_contracts.dart`, `test/contract/**` | 공용 시험이라 고치면 세 명 모두 영향 → 팀 방 공지 | 구현마다 `test/ports/`에 자기 시험 파일만 추가 |

---

## 4. 결합(바꿔 끼우기) 절차

1. 자기 브랜치에서 진짜 구현을 만든다 (예: `feat/guidance-db`).
2. 해당 포트의 **공용 시험**을 통과시킨다 — `test/ports/`에 한 줄 추가:
   `void main() => guidanceRepositoryContract('로컬 DB', () => DbGuidanceRepository(...));`
3. `lib/bootstrap.dart`에서 **자기 포트 줄 하나만** 진짜 구현으로 바꾼다.
4. 전체 확인: `flutter analyze` 0건, `flutter test` 전부 통과, (Kotlin이면) JUnit 통과.
5. 에뮬레이터 결합 점검표(7장)의 해당 줄을 직접 확인하고 PR에 적는다.
6. 본인이 아닌 팀원 한 명이 리뷰 → `main`에 Merge.
7. 다른 두 명은 그날 `main`을 받아(`git pull origin main`) 자기 브랜치에 반영한다.

**결합의 날**: 매주 **금요일**. 그 주에 바꿔 끼운 것을 `main`에서 셋이 같이 에뮬레이터로 확인한다.

---

## 5. 일정 (4주)

### 결합 마일스톤

| 날짜 | 마일스톤 | 무엇이 진짜가 되나 |
|---|---|---|
| **11/13(금)** | M0 골격 공유 | `main`에 골격, 셋 다 실행 확인 |
| **11/20(금)** | M1 실제 입력·분석 | C1 분석 채널, C2 사진 가져오기, C3 스키마·메모리 구현 |
| **11/27(금)** | M2 실제 데이터 | C3 로컬 DB + 실제 앱 기능 3개, C4 이력, C5 공유, 개인정보 결과 확정 |
| **12/2(수)** | M3 서버 (선택) | C6 Firebase 갱신·동기화 — 안 되면 제외 |
| **12/4(금)** | **기능 동결** (마지막 결합의 날) | 이후 버그 수정만 |
| **12/6(일)** | 제출 | |

### 1주차 (11/10~11/15) — 골격 공유와 준비

| 팀원 | 할 일 | 금요일까지 결과 |
|---|---|---|
| 공통 | 확인용 zip 확인 → 의견 → `feat/skeleton` PR·Merge, 각자 clone·실행 | M0 |
| 공통 | **MVP 대상 앱 1~2개·기능 3개 결정** — 기능 맵 스키마·앵커·선택자가 여기에 달려 있어 1주차에 정해야 3주차 실제 맵이 가능 | 대상 앱·기능 목록 |
| 팀원 1 | C1 시작: `MainActivity`·`Analyzer` 계약 형식으로, `contract_fixtures` 읽는 JUnit 추가 | 채널 초안 |
| 팀원 2 | G·GS·RG Figma 대조, Gate 비활성 표시 통일, 카메라 흐름 화면(CP·C·CR·CA·RC)·DENY를 가짜로 | 화면 초안 |
| 팀원 3 | 기능 맵 스키마 확정(문서), C3 메모리 구현, C2 image_picker 구현 시작 | 스키마 문서 |

### 2주차 (11/16~11/22) — M1 실제 입력·분석

| 팀원 | 할 일 |
|---|---|
| 팀원 1 | C1 완료(마감 11/20), OCR 로그 제거, `\b` 결함 수정 시작 |
| 팀원 2 | G·카메라 화면을 `ImageInput`에 연결, 취소·권한 거부·읽기 실패 화면 처리, P·SHARE 화면을 가짜로 |
| 팀원 3 | C2 완료(마감 11/20), C3 공용 시험 통과, 1주차에 정한 대상 앱의 화면별 스크린샷 수집·앵커 후보 정리(팀원 1과) |
| **11/20 결합** | 진짜 사진 → 진짜 Kotlin 분석 → 결과 화면. 비행기 모드 확인 |

### 3주차 (11/23~11/29) — M2 실제 데이터

| 팀원 | 할 일 |
|---|---|
| 팀원 1 | 개인정보 후보 확정(`\b` 수정, 유형별 3건 이상 시험 세트, ML Kit 검출률 기록), 실제 앱 스크린샷으로 화면 식별·대상 찾기 정확도 확인 |
| 팀원 2 | 기능 목록을 진짜 `GuidanceRepository`로, HISTORY·SETTINGS 화면, "화면이 달라요" 재촬영, P → SHARE 연결과 공유 경로 전수 시험 |
| 팀원 3 | C3 로컬 DB + 실제 기능 3개 맵, C4 이력 DB, C5 share_plus (마감 11/27) |
| **11/27 결합** | 실제 앱 기능 3개를 인터넷 없이 안내, 기록 저장·다시 보기, 공유는 P를 거침 |

### 4주차 (11/30~12/6) — M3·안정화·제출

| 날짜 | 팀원 1 | 팀원 2 | 팀원 3 |
|---|---|---|---|
| 11/30~12/2 | 3초 측정(20회 중 18회), 네트워크 로그로 외부 전송 0건 확인, release proguard 규칙 | integration_test, 글꼴 최대 크기, 3초 초과 표시 확인, (C6 들어오면) 설정에 revision·동기화 동의 | C6 Firebase(마감 12/2, 안 되면 제외), CI(analyze·test 자동) |
| 12/3 | 버그 수정 | 버그 수정 | 버그 수정 |
| **12/4** | **기능 동결** — 전체 결합 점검표 통과 확인 | | |
| 12/5~12/6 | 측정 결과 정리 | 데모 순서·화면 캡처 | 보고서 데이터 부분 |

---

## 6. 매주 하는 일 (공통 규칙)

- 월: 이번 주 할 일과 금요일 결합 대상 확인 (팀 방에 한 줄씩)
- 수: 중간 점검 — 마감이 위험하면 **수요일에 알린다** (금요일에 알면 늦음)
- 금: 결합의 날 — PR Merge, `main`에서 결합 점검표 확인
- PR 전: `flutter analyze` 0건, `flutter test` 통과, (Kotlin) JUnit 통과, 에뮬레이터 확인
- 늦어지면: 화면·흐름은 가짜로 계속 진행한다. 결합만 다음 금요일로 미룬다.

---

## 7. 결합 점검표 (에뮬레이터에서 직접 확인)

| # | 확인 | 관련 | 확인 시점 |
|---|---|---|---|
| 1 | 홈 → 갤러리 → 사진 선택 → 분석 → 결과 → 단계 안내 → 완료가 끊김 없이 진행 | C1 C2 C3 | M1 |
| 2 | 사진 선택 취소 → 이전 화면, 권한 거부 → DENY, 손상 파일 → E (앱 종료 없음) | C2 | M1 |
| 3 | 지원하지 않는 화면 → E "다시 촬영해 주세요" (추정 안내 없음) | C1 | M1 |
| 4 | 분석 중 취소 → GR 유지, 3초 넘으면 "조금 더 걸리고 있어요" | C1 | M1 |
| 5 | 비행기 모드에서 1~4 동일 | 전체 | M1, M2 |
| 6 | 개인정보 후보가 있는 사진 → 결과 화면 경고, 가린 값(앞 3자·뒤 2자)만 표시 | C1 | M2 |
| 7 | RG·DONE·HISTORY 어디서 공유해도 P를 거침, 후보 0건이어도 P 표시, 공유 내용은 사용 방법 텍스트만 | C5 | M2 |
| 8 | 실제 앱 1~2개의 기능 3개 안내가 인터넷 없이 동작 | C3 | M2 |
| 9 | 안내 기록 저장 → 앱 재시작 후 HISTORY에 남음, 원본 사진 없음 | C4 | M2 |
| 10 | 기능 맵 갱신 실패(인터넷 끊김) 시에도 안내 계속, 이전 revision 유지 | C6 | M3 |
| 11 | 글꼴 최대 크기에서 안내 화면이 깨지지 않음 | 화면 | 동결 전 |

---

## 8. 위험과 대응

| 위험 | 영향 | 대응 |
|---|---|---|
| C1(Kotlin 채널)이 11/20을 넘김 | 진짜 분석으로 결합 불가 | 화면·데이터는 가짜로 계속. 수요일(11/18)에 위험 공유, 필요하면 팀원 2가 Flutter 쪽 확인 지원 |
| 실제 앱 화면이 앵커·선택자와 안 맞음 | 화면 식별 실패 → E | 팀원 1·3이 실제 스크린샷으로 함께 맵 검증(3주차). 앵커는 화면마다 2개 이상, 자주 바뀌지 않는 글자로 |
| Firebase가 늦음 | 4단계 미완 | 12/2까지 안 되면 제외. 로컬 맵으로 핵심 기능은 동작 |
| 에뮬레이터 공간 부족·설치 멈춤 | 확인 지연 | Device Manager → Wipe Data, 확인은 `flutter build apk --debug --target-platform android-x64` |
| release 빌드 즉시 종료(R8) | 제출용 빌드 불가 | 4주차 초 팀원 1이 ML Kit proguard keep 규칙 추가, 12/2까지 release 실행 확인 |
| 공용 파일(포트·계약) 동시 수정 | 충돌 | 3장 소유권 규칙. 바꾸기 전 팀 방 공지 |

---

## 부록: 지금 코드에서 각 연결 지점 위치

| 연결 지점 | 포트 | 가짜 구현 | 공용 시험 |
|---|---|---|---|
| C1 분석 | `lib/domain/screen_analyzer.dart` | `lib/data/fake_analyzer.dart` | `test/contract/fixtures_test.dart` + `contract_fixtures/analyze/` |
| C2 사진 | `lib/domain/image_input.dart` | `lib/data/fakes.dart` `FakeImageInput` | `test/ports/port_contracts.dart` `imageInputShapeContract` |
| C3 기능 맵 | `lib/domain/guidance.dart` | `lib/data/demo_guidance.dart` | `guidanceRepositoryContract` |
| C4 이력 | `lib/domain/history.dart` | `fakes.dart` `InMemoryHistoryRepository` | `historyRepositoryContract` |
| C5 공유 | `lib/domain/share_and_update.dart` `Sharer` | `fakes.dart` `FakeSharer` | (P 경로 전수 시험, 팀원 2) |
| C6 갱신 | `lib/domain/share_and_update.dart` `MapUpdater` | `fakes.dart` `FakeMapUpdater` | (에뮬레이터 점검표 10) |
| 조립 | `lib/bootstrap.dart` | — | — |
