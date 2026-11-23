# screen_guide — 오류 수정 현황 & 테스트 가이드

- 작성: 2026-11-23
- 대상: `screen_guide/` (새 아키텍처 앱, Flutter 3.47.9 / Dart 3.13.7)
- 기준 커밋: `analysis` 브랜치 · HEAD `9d42278` (feat/history-db + feat/history-share 병합 후) + 이번 EXIF 수정
- 이 문서의 목적: **① 무엇을 고쳤고 무엇이 남았는지 ② 기능이 어디까지 돌아가는지 ③ 그래서 어떻게 테스트해야 하는지**

> ⚠️ 이 폴더의 `AGENT.md`는 "최신 실행 소스 = `screen_guide_test/`"라고 선언한다.
> 이 문서는 **`screen_guide/`(새 아키텍처)** 기준이다. 두 앱 중 무엇을 최종 제출/최신으로 볼지 팀이 먼저 확정해야 한다
> (아래 §9-1). 확정 전까지 이 문서는 "새 아키텍처 앱의 검증 기록"으로만 읽어야 한다.

> ✅ 검증 수준: 코드 정적 분석 완료. **자동 테스트는 이 문서 작성 환경에 Flutter/Dart/Kotlin 툴체인이 없어 미실행**이다.
> 따라서 §4의 "기대 결과"는 코드에서 읽어낸 값이고, **실제 통과 판정은 개발 PC에서 돌린 출력으로 남겨야 한다.**

---

## 목차
1. 수정 현황 요약
2. 이번 수정 상세 (EXIF)
3. 기능 리스트 (구현 상태)
4. 자동 테스트 — 돌리는 방법과 기대값
5. 수동 테스트 — 시나리오 체크리스트
6. 테스트 데이터 준비
7. 증거 수집 규칙
8. 제출 전 체크리스트
9. 남은 수정 작업
10. 부록 — 명령 모음 / 파일:라인

---

# 1. 수정 현황 요약

| 구분 | 건수 | 내용 |
|---|---|---|
| ✅ 수정 완료 | **1** | E-1 EXIF 회전 (카메라 세로 사진에서 위치 상자 어긋남) |
| ⬜ 미수정 | **12** | E-2~E-6, E-8~E-14 |
| ⏳ 팀 결정 | **1** | E-7 공유 결과 `unavailable → sent` 해석 |

| ID | 제목 | 위치(핵심) | 상태 | 사용자 영향 |
|---|---|---|---|---|
| E-1 | EXIF 회전 미반영 → 상자 어긋남 | `Analyzer.kt` / `ScreenImage` | ✅ | 카메라 세로 사진에서 안내 위치 틀림 |
| E-2 | 공유 시트 예외 시 SHARE에 갇힘 | `guide_flow.dart:598` | ⬜ | 눌러도 무반응 |
| E-3 | 갤러리 읽기 실패가 "사진 없음"으로 위장 | `media_gallery_input.dart:144` | ⬜ | 있는 사진이 없다고 보임 |
| E-4 | 흐름 계층 `catch` 0개 | `guide_flow.dart:238/247` | ⬜ | 예외 시 화면 정지 |
| E-5 | 분석 취소가 늦은 결과로 덮어써짐 | `guide_flow.dart:469` | ⬜ | 취소했는데 결과 화면으로 튐(잠재) |
| E-6 | 완료 화면 연타 → 기록 중복 | `guide_flow.dart:522` | ⬜ | 같은 기록 N건 |
| E-7 | `unavailable → sent` | `share_plus_sharer.dart:44` | ⏳ | "공유했어요"가 거짓일 수 있음 |
| E-8 | 기록 재조회 실패 시 펼침 미정리 | `guide_flow.dart:663` | ⬜ | 없는 기록이 펼쳐진 채 남음(사소) |
| E-9 | P 진입 draft null 시 무반응 버튼 | `app.dart:93` / `guide_flow.dart:589` | ⬜ | 방어 필요 |
| E-10 | DB `close()` 호출자 0 | `sqlite_history_repository.dart:111` | ⬜ | 현재 무해(수명주기) |
| E-11 | 화면 11개가 홈으로 조용히 폴백 | `app.dart:109` | ⬜ | 잘못된 화면 표시 가능 |
| E-12 | `coordinate_mapper` 미병합(중복) | `screen_image.dart:73-80` | ⬜ | 동작 무관, 병합 시 정리 |
| E-13 | `ShareDraft`가 app 계층 / 885줄 | `guide_flow.dart:855` | ⬜ | 유지보수 |
| E-14 | `.gitattributes` 없음(CRLF/LF) | 루트 | ⬜ | diff 234파일, 커밋 오염 |

---

# 2. 이번 수정 상세 (E-1 EXIF)

## 2-1. 문제

카메라로 세로로 들고 찍은 사진(EXIF Orientation 6/8 = 90°/270°)에서
**안내 상자가 실제 버튼이 아닌 엉뚱한 곳에 그려지고, 사진이 늘어나 보인다.**
갤러리 스크린샷(PNG, 회전 0°)에서는 정상 → 카메라 촬영에서만 재현.

## 2-2. 원인 (값의 기준이 서로 달랐다)

```
Kotlin  InputImage.width/height      = 회전 전 비트맵 크기     (예: 1080×2400)
ML Kit  boundingBox                  = 회전이 적용된 좌표      (실제로는 2400×1080 화면)
Flutter Image.file                   = EXIF를 적용해 "세워서" 그림
        → 응답 imageSize만 회전 전이라 세 값의 기준이 어긋남
```

## 2-3. 수정 (3파일)

| 파일 | 변경 |
|---|---|
| `android/.../logic/GuideLogic.kt` | **+11** — `uprightSize(width, height, rotationDegrees)` 순수 함수 |
| `android/.../Analyzer.kt` | **+5 / -1** — 응답 `width/height`를 `uprightSize(...)` 결과로 교체, 회전 로그 1줄 |
| `android/.../src/test/.../UprightSizeTest.kt` | **신규 28줄, @Test 5건** |

```kotlin
// logic/GuideLogic.kt:23
fun uprightSize(width: Int, height: Int, rotationDegrees: Int): Pair<Int, Int> {
    val normalized = ((rotationDegrees % 360) + 360) % 360
    return if (normalized == 90 || normalized == 270) height to width else width to height
}
```
```kotlin
// Analyzer.kt:62-66
val (uprightWidth, uprightHeight) =
    uprightSize(image.width, image.height, image.rotationDegrees)
Log.i(tag, "rotation ${image.rotationDegrees}°, size ${uprightWidth}x${uprightHeight}")
onDone(ChannelCodec.encode(AnalyzeResult(
    requestId = req.requestId, width = uprightWidth, height = uprightHeight,
```

## 2-4. 검증 상태

| 항목 | 결과 |
|---|---|
| 변경 내용 diff | Analyzer.kt `+5/-1`, GuideLogic.kt `+11` (`git diff --ignore-cr-at-eol --stat`) |
| 괄호 균형 | PASS |
| NUL 바이트 / 줄 수 | 0 / 121·144·28 |
| Kotlin 컴파일 | **미실행** (툴체인 없음) |
| JUnit 5건 | **미실행** |
| 실기기 좌표 | **미검증** → §5 T5 절차 |

## 2-5. 되돌리는 법

`git checkout -- <Analyzer.kt> <GuideLogic.kt>` 후 `UprightSizeTest.kt` 삭제.
(계약 형식·Dart 모델은 건드리지 않았으므로 Flutter 쪽은 롤백 불필요)

---

# 3. 기능 리스트 (구현 상태)

범례: ✅ 완료 · 🟡 구조는 있으나 가짜/부분 · 🚫 이번 범위 아님

| # | 기능 | 화면/단계 | 코드 위치 | 상태 | 자동 시험 |
|---|---|---|---|---|---|
| 1 | 갤러리에서 1장 고르기 | G → GS → GR | `features/capture/data/media_gallery_input.dart` | ✅ (실기기 사진) | `media_gallery_input_test` |
| 2 | 카메라로 1장 찍기 | CP → (기기 카메라) → CR | `picker_camera_input.dart` | ✅ | `picker_camera_input_test` |
| 3 | 권한 거부 → DENY → 설정/다른 방법 | DENY | `guide_flow.dart:_onPickFailed` + `deny_screen.dart` | ✅ | `guide_flow_test` |
| 4 | 읽기 실패 → E | E | `_fail` + `error_screen.dart` | ✅ (목록 실패는 E-3) | `guide_flow_test` |
| 5 | 분석 (가짜 분석기, 기본값) | GA/CA → RG/RC | `analyze/data/fake_analyzer.dart` | ✅ 체험용 | `analyzers_test` |
| 6 | 분석 (실제 Kotlin ML Kit) | GA/CA → RG/RC | `MethodChannelAnalyzer` ↔ `Analyzer.kt` | ✅ `--dart-define=FAKE_ANALYZER=false` | Kotlin `ChannelCodecTest` |
| 7 | 화면 식별(앵커 2개 이상) | RG/RC | `logic/GuideLogic.kt:identifyScreen` | ✅ | Kotlin `RulesTest` (R1·R2) |
| 8 | 기능 목록 | RG/RC | `AssetGuidanceRepository.actionsFor` | ✅ 맵 2화면 3기능 | `feature_map_test` |
| 9 | 단계 안내 + 대상 상자 | D1~D5 | `guide_flow.dart:_locate` + `shared/cells/screen_image.dart` | ✅ (EXIF 수정 반영) | 위젯 `widget_test` |
| 10 | 개인정보 후보 표시 | RG/RC | `analysis.dart:pii` + `result_screen.dart` | ✅ 표시만 | Kotlin `RulesTest` (R4·R5) |
| 11 | 안내 완료 | DONE | `done_screen.dart` | ✅ | `guide_flow_test` |
| 12 | 기록 저장(로컬 DB) | DONE | `sqlite_history_repository.dart` | ✅ sqflite | `history_repository_contract_test` |
| 13 | 기록 목록/펼침/삭제 | HISTORY | `history_screen.dart` + `_openHistory` | ✅ | `history_screen_test` |
| 14 | 공유 전 확인(P) → SHARE → 시스템 시트 | P → SHARE | `privacy_check_screen.dart` / `share_screen.dart` / `share_plus_sharer.dart` | ✅ 텍스트만 | `share_paths_test` 등 |
| 15 | 설정(권한 관리, 맵 버전) | SETTINGS | `settings_screen.dart` | ✅ | `settings_screen_test` |
| 16 | 동기화 동의 | SETTINGS | — | 🚫 `notReady` | — |
| 17 | 실시간 안내(오버레이) | LP~LG5 | — | 🚫 `notReady` (화면 라우팅 없음) | — |
| 18 | 기능 맵 자동 갱신 | — | `FakeMapUpdater` | 🟡 가짜 | — |

> 체험(가짜 분석기) 모드의 샘플: `assets/samples/sample_settings.png`, `sample_chat.png`
> 지원 화면/기능(맵): `demo.settings`(앵커: 네트워크 및 인터넷·알림 설정·배터리·디스플레이),
> `demo.chat`(앵커: 대화·메시지 입력·보내기).
> 기능: `settings.notification`(1단계), `settings.display`(1단계), `chat.send`(2단계).

---

# 4. 자동 테스트 — 돌리는 방법과 기대값

## 4-1. 준비

```powershell
cd D:\dev\On-screen-Guide_MobileProject\screen_guide
flutter --version          # 3.47.9 확인 (팀 공통)
flutter pub get
```

## 4-2. 실행 3종

| # | 명령 | 기대 결과 | 실패하면 |
|---|---|---|---|
| A | `flutter analyze` | **0 issues** | 경고 대부분은 `empty_catches`(catch (_) 18곳, E-4 계열). 실제 오류와 구분해 읽기 |
| B | `flutter test` | 전부 pass (선언 215곳, 포트 공용 시험이 여러 번 호출되어 실행 건수는 더 많음) | 먼저 `test/ports/*` 부터 (계약 위반이면 나머지도 연쇄 실패) |
| C | `cd android; .\gradlew.bat :app:testDebugUnitTest` | **72건 pass** (GuideLogic 28 + Rules 32 + ChannelCodec 7 + **UprightSize 5**) | Gradle wrapper 없으면 `flutter build apk` 1회 먼저 |

## 4-3. 이번 수정의 자동 검증 포인트

- `UprightSizeTest` 5건이 **실패하면 EXIF 수정이 깨진 것**이다(특히 `_90도는_가로세로를_바꾼다`).
- `flutter test`는 EXIF를 직접 검증하지 못한다(Kotlin 영역). **EXIF는 반드시 §5 T5 실기기로 확인**해야 한다.
  → 이 공백을 메우려면 Kotlin 쪽 `uprightSize` 시험 + 실기기 1회가 최소 세트다.

## 4-4. 시험 구조(왜 이렇게 나눴나)

| 층 | 파일 | 보증하는 것 |
|---|---|---|
| 공용 계약 | `test/ports/port_contracts.dart` + `*_contract_test.dart` | 진짜 구현이 가짜와 같은 계약을 지키는가 (DB는 ffi 메모리 DB로 동일 SQL) |
| 도메인 | `test/shared/contracts/*`, `test/features/guidance_map/*` | JSON/좌표/화면 ID 규칙 |
| 흐름 | `test/app/guide_flow_test.dart`, `share_paths_test.dart` | 관문·전이·공유 경로 전수 |
| 화면 | `test/widget_test.dart`, `test/features/*/ui/*` | 문구·버튼·상자 렌더 |
| Kotlin | `android/app/src/test/...` | 채널 형식(fixtures) + 분석 규칙 + EXIF 크기 보정 |

---

# 5. 수동 테스트 — 시나리오 체크리스트

> 표기: **기대** = 통과 기준. **증거** = 제출/기록에 남길 것.
> 실패 시 먼저 볼 곳을 함께 적었다.

## T1. 체험 모드 기본 흐름 (가짜 분석기, 5분)

```powershell
flutter run            # 기본값 = 가짜 분석기
```

| 단계 | 조작 | 기대 |
|---|---|---|
| 1 | 앱 시작 | 홈: "어떤 방법으로 시작할까요?" + 입력 3칸(카메라/갤러리/실시간) |
| 2 | "갤러리에서 선택" | "최근 이미지" 목록에 샘플 2장(설정/채팅) |
| 3 | 설정 샘플 선택 → "선택한 이미지 사용" | "이 이미지로 안내받을까요?" (GR) |
| 4 | "이 화면 분석하기" | "이미지 분석 중" → 결과 "무엇을 하고 싶으세요?" |
| 5 | 결과 화면 | 글자 수·ms 표시, 기능 2개(알림 설정 바꾸기 / 글자 크기 바꾸기) |
| 6 | "알림 설정 바꾸기" | "단계별 안내 · 1 / 1", "알림 설정을 눌러주세요", 상자 1개 |
| 7 | "안내 완료" | "잘 따라오셨어요!" |
| 8 | "안내 기록에 저장" | 스낵바 "안내 기록에 저장했어요" |
| 9 | "새로운 화면 안내받기" | 홈 복귀 |

실패 시: `test/widget_test.dart`의 같은 시나리오와 문구 대조.

## T2. 2단계 기능 + 카메라 흐름 (실제 분석기)

```powershell
flutter run --dart-define=FAKE_ANALYZER=false
```

| 단계 | 기대 |
|---|---|
| 갤러리에서 채팅 샘플 → 분석 | 기능 "메시지 보내기"(2단계) 표시 |
| 기능 선택 → D1 | "메시지 입력 칸을 눌러주세요" + 상자 |
| "다음 단계" → D2 | "보내기를 눌러주세요" + 상자 이동 |
| 홈 → 카메라 → "카메라 허용" | 기기 카메라 앱 실행 |
| 촬영 → CR | "촬영한 사진", "이 화면 분석하기" |

## T3. 권한 거부 → 복구

| 단계 | 기대 |
|---|---|
| 카메라 "허용"에서 권한 거부 | DENY: "카메라 권한이 허용되지 않았어요" |
| "카메라 권한 확인" | 기기 설정(앱 권한) 화면 → 뒤로 |
| DENY에서 "갤러리에서 선택" | 갤러리 목록으로 대체 진입 (막히지 않음) |

## T4. 실패 복구 (지원하지 않는 화면)

| 단계 | 기대 |
|---|---|
| 지원 목록에 없는 앱 화면을 갤러리에서 선택 → 분석 | E: "어떤 화면인지 알 수 없어요" |
| "다른 이미지 선택" | 갤러리로 복귀 |
| 사진을 흐리게/잘라서 대상 못 찾게 → 안내 시작 | E: "누를 곳을 찾지 못했어요" (추정 안내 금지) |

## T5. ★ EXIF 좌표 검증 (이번 수정 — 필수)

**준비**: 세로로 들고 찍은 사진 2장
- (a) 휴대폰 카메라로 세로 촬영한 사진
- (b) `exiftool -Orientation=6 photo.jpg` 로 만든 회전 태그 사진 (또는 Orientation=8)

| 단계 | 기대 |
|---|---|
| 1 | `flutter run --dart-define=FAKE_ANALYZER=false` |
| 2 | `adb logcat -s ScreenGuide` 켜 두기 |
| 3 | (a)로 갤러리 선택 → 분석 → 로그 확인: **`rotation 90°, size 2400x1080`**(가로가 더 커야 함) |
| 4 | 결과 화면: 사진이 **찌그러지지 않고**, 요소 테두리가 실제 글자/버튼 위에 있음 |
| 5 | 안내 단계: 상자가 **실제 버튼을 감싼다** (손가락으로 눌러 확인) |
| 6 | (b) 270°도 동일. 스크린샷(PNG)은 **`rotation 0°` + 원래 크기** |
| 7 | `rotation 0°, size 1080x2400`이 나오면 보정이 동작한 것 |

실패 시:
- 상자가 90° 돌아가 있으면 → `Analyzer.kt`의 `uprightSize` 적용 확인(응답 `imageSize`가 세워진 값인지)
- 상자 크기는 맞는데 위치만 틀리면 → `ScreenImage`의 `sx/sy`(표시 크기/이미지 크기) 계산 확인
- 그래도 틀리면 → 대안(비트맵 자체 회전 후 `InputImage.fromBitmap`)으로 전환. 이때 사진 메모리가 2배가 되므로 큰 사진에서 OOM 주의

## T6. 분석 취소 (E-5 잠재 결함 확인)

| 단계 | 기대(현재 코드) |
|---|---|
| 분석 중 "분석 취소" | GR/CR로 복귀, 결과 화면으로 튀지 않음 |
| 반복 5회 | 동일 |
> 실제로 튀면 E-5 재현 성공 → `guide_flow.dart:469` 뒤에 화면 재확인 1줄 필요.

## T7. 기록 영속 (MP3 기준)

| 단계 | 기대 |
|---|---|
| 안내 완료 → "안내 기록에 저장" | 스낵바 |
| 앱 강제 종료(`adb shell am force-stop <패키지>`) → 재실행 | 홈 |
| 하단 "기록" 탭 | 저장한 기록 1건, "기능 제목 · 입력방식 · 시각" |
| 기록 줄 탭 | 단계 문구 펼침 + "이 안내 공유하기" |
| "지우기" → 확인 | 목록에서 사라짐, 재실행 후에도 없음 |
| 앱 데이터 삭제 후 | "아직 저장한 안내가 없어요" |

## T8. 공유 (P → SHARE)

| 단계 | 기대 |
|---|---|
| DONE → "공유하기" | P: "공유하기 전에 한 번 더 확인해요" + 후보 N건 |
| "확인했어요 · 사용 방법만 공유" | SHARE: 미리보기 글(제목 + 단계 + 고정 문구) |
| "보내기" | Android 시스템 공유 시트, **텍스트만** |
| 시트 닫기 | SHARE로 돌아오지 않고 **들어온 곳(DONE)** 복귀 |
| SHARE에서 ‹ | P로 한 칸 |
| P에서 ‹ | 들어온 곳(DONE 또는 기록) |
| 기록에서 공유 후 복귀 | 기록 목록 + 그 기록 펼침 상태 |

## T9. 설정

| 단계 | 기대 |
|---|---|
| 하단 "설정" | "카메라·사진 권한 관리", "저장한 안내 기록", "안내 자료 버전" |
| "카메라·사진 권한 관리" | 기기 앱 설정 열림 |
| "안내 자료 버전" | `2026-11-13.1` (맵 revision) |

## T10. 알려진 결함 확인 (수정 전 확인용)

| 확인 | 현재 예상 동작(결함) |
|---|---|
| DONE에서 "저장" 연타 2회 | 기록 2건 (E-6) |
| 공유 시트에서 예외(비행기 모드 등) | SHARE에 갇힘 (E-2) — **수정 전에는 재현될 수 있음** |
| 사진은 있는데 목록이 빔 | "최근 사진이 없어요" (E-3) |

---

# 6. 테스트 데이터 준비

| 무엇 | 어떻게 |
|---|---|
| 체험용 샘플 2장 | 저장소 `screen_guide/assets/samples/` (수정 금지) |
| 지원 화면 기준 | `assets/feature_maps/sample_v1.json` — 화면 2개·기능 3개 |
| EXIF 90° | 휴대폰 세로 촬영 / `exiftool -Orientation=6 -n in.jpg` |
| EXIF 270° | `exiftool -Orientation=8 -n in.jpg` |
| 지원 안 하는 화면 | 아무 앱의 목록/설정이 아닌 화면 캡처 |
| 긴 글 화면 | 기사/메모 캡처(개인정보 후보 확인용) |

---

# 7. 증거 수집 규칙

```powershell
adb devices
adb logcat -s ScreenGuide                     # 분석 로그 (rotation/size/시간)
adb shell run-as <패키지> ls code_cache       # 남은 sg_ 복사본 확인
adb shell am force-stop <패키지>              # 재시작 시나리오
```

- 스크린샷은 **실제 기기/에뮬레이터 화면만** 사용(생성 시안 금지).
- EXIF 검증은 **로그 1장 + 화면 1장**을 세트로 남긴다(로그가 없으면 보정이 돌았는지 알 수 없다).
- 실패 재현도 증거다 — "무엇이 기대와 달랐는지"를 한 줄로 적는다.

---

# 8. 제출 전 체크리스트

- [ ] `flutter analyze` 0 issues (또는 경고 목록을 기록)
- [ ] `flutter test` 전부 pass (출력 붙여넣기)
- [ ] `:app:testDebugUnitTest` 72건 pass
- [ ] T1~T5 수동 시나리오 통과 + 스크린샷
- [ ] T7·T8(기록·공유) 통과 — MP3 기준
- [ ] ZIP에서 `build/`, `.dart_tool/`, `.gradle/`, `.idea/`, 비밀키 제외
- [ ] ZIP 최상위: `app/`, `README.md`, `screenshots/`, `prompts_log.md`, (`PRIVACY.md`)
- [ ] 20MB 제한 확인

---

# 9. 남은 수정 작업

## 9-1. 먼저 결정할 것 (사람)

1. **제출/최신 앱 확정**: `screen_guide` vs `screen_guide_test`
   → `docs/AGENT.md`와 `screen_guide/README.md`의 문구를 같은 기준으로 고친다.
2. **E-7 공유 결과 정책**: `unavailable`을 `sent`로 볼지 / `dismissed`로 볼지 / 문구를 중립화할지.

## 9-2. 코드 수정 (권장 순서)

| 순서 | 작업 | 파일 | 규모 |
|---|---|---|---|
| 1 | `dispatch` 최상위 `try/catch` + `notifyListeners`를 `finally`로 | `guide_flow.dart:238` | ~10줄 |
| 2 | `_shareSend` `catch` (실패 시 안내 + `_leaveShare`) | `guide_flow.dart:598` | ~6줄 |
| 3 | 취소 가드 `if (screen.stage != Stage.analyze) return;` | `guide_flow.dart:469` | 1줄 |
| 4 | 저장 멱등/버튼 잠금 | `guide_flow.dart:522` + `done_screen.dart` | ~5줄 |
| 5 | 갤러리 실패 구분(`GalleryPage{failed}`) | `image_input.dart`, `media_gallery_input.dart`, `gallery_screen.dart` | ~20줄 |
| 6 | `_openEntry` 미발견 시 펼침 정리 | `guide_flow.dart:663` | 1줄 |
| 7 | P 버튼 비활성 조건(draft null) | `guide_flow.dart:589` | 1줄 |
| 8 | `.gitattributes` + `git add --renormalize .` | 루트 | 1파일 |
| 9 | `ShareDraft`/`ShareCandidate` → `features/share/domain/` | 구조 | 중 |
| 10 | `GuideFlow` 분리(기록/공유), DB close 수명주기, 미라우팅 화면 명시 | 구조 | 큼 |

---

# 10. 부록

## 10-1. 명령 모음

```powershell
cd D:\dev\On-screen-Guide_MobileProject\screen_guide
flutter pub get
flutter analyze
flutter test
flutter run                                          # 체험(가짜 분석기)
flutter run --dart-define=FAKE_ANALYZER=false        # 실제 Kotlin 분석기
cd android; .\gradlew.bat :app:testDebugUnitTest      # Kotlin 72건
```

```bash
# 변경 내용만 보기 (CRLF 노이즈 제거)
git diff --ignore-cr-at-eol --stat -- screen_guide

# 이번 수정 확인
git diff --ignore-cr-at-eol -- screen_guide/android/app/src/main/kotlin/com/screenguide/screen_guide/Analyzer.kt
```

## 10-2. 파일:라인 인덱스 (문제 위치)

| 무엇 | 위치 |
|---|---|
| 흐름/게이트 | `lib/app/guide_flow.dart:177`(allowed), `:238`(dispatch), `:247`(handle) |
| 분석 | `:434`(_analyze), `:460`(_analyzeFirst), `:469`(레이스 지점), `:489`(_locate) |
| 기록 | `:522`(_saveHistory), `:650`(_openHistory), `:663`(_openEntry), `:679`(_deleteEntry) |
| 공유 | `:549`(_sharePrepare), `:589`(_shareConfirm), `:598`(_shareSend), `:621`(_leaveShare) |
| 단계 훅 | `:790`(_onExit), `:817`(_onEnter) |
| 화면 선택 | `lib/app/app.dart:69`, 폴백 `:109` |
| 좌표 그리기 | `lib/shared/cells/screen_image.dart:71-113` |
| DB | `lib/features/history/data/sqlite_history_repository.dart:22` |
| 공유 구현 | `lib/features/share/data/share_plus_sharer.dart:25`, 결과 해석 `:41` |
| 갤러리 | `lib/features/capture/data/media_gallery_input.dart:131` |
| EXIF (수정) | `android/.../Analyzer.kt:62-66`, `.../logic/GuideLogic.kt:23`, 테스트 `.../UprightSizeTest.kt` |

## 10-3. 이 문서에서 검증하지 못한 것

1. `flutter analyze` / `flutter test` 실제 출력
2. Kotlin 72건 실제 실행
3. EXIF 90°/270° 실기기 좌표 정합
4. `sqflite` 첫 open, `share_plus` 실제 시트, `photo_manager` "일부 사진만 허용" 분기
5. 4.4GB 작업트리에서의 빌드 시간(ZIP 제외 규칙은 §8)
