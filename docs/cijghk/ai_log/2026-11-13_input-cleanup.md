# InputCleanup (앱 복사본 정리 · 권한 설정 열기) — 2026-11-13

브랜치: `feat/camera-input` (PR #3에 이어서) · 도구: Claude Code (Opus 5.5)
기준: `협업규격_최종` 2장(의존 규칙)·3.1·3.4(호출 시점)·4.3 #4, `기능별_검토_결론` 1장, `docs/cijghk/데이터_입출력_설계.md` 4-3

## 1. 맡긴 일

`InputCleanup`의 진짜 구현을 만들어 공용 시험을 통과시키고 `bootstrap`의 `inputCleanup` 줄을 바꾼다.
조건: 앱 복사본만 지우고 사용자 원본은 지우지 않음, 예외를 던지지 않음, 카메라 취소 때 `cache/`에 남는 0바이트 파일(11/12 발견)도 정리, 기기의 앱 권한 설정 화면 열기.

## 2. 받은 구조

| 파일 | 하는 일 |
|---|---|
| `lib/features/capture/data/file_input_cleanup.dart` | `FileInputCleanup`. `release`(앱 복사본 폴더 삭제), `clearLeftovers`(`sg_` 복사본 + image_picker 잔여 파일 삭제), `openAppSettings`(`app_settings` 패키지) |
| `test/features/capture/data/file_input_cleanup_test.dart` | 시험 10건 |
| `test/ports/input_cleanup_contract_test.dart` | 공용 시험 `inputCleanupContract`에 진짜 구현 1건 |
| `lib/app/bootstrap.dart` | `inputCleanup` 줄만 `FileInputCleanup()`으로 교체, 표 주석 갱신 |
| `pubspec.yaml`, `pubspec.lock` | `app_settings: ^9.0.1` 추가 (공용 파일) |

흐름이 부르는 때(규격 3.4, 골격 `guide_flow.dart`에 이미 연결됨): 앱 시작 → `clearLeftovers`, 세션이 끝날 때(홈으로·다시 고르기·오류 뒤) → `release`, 권한 안내 화면 → `openAppSettings`.

## 3. 하나씩 물어본 것

| 물어본 것 | AI의 설명 |
|---|---|
| 설정 화면을 왜 Kotlin 채널이 아니라 패키지로 여나 | 규격 2장 의존 규칙 "Kotlin을 부르는 Dart 코드는 `MethodChannelAnalyzer` 하나뿐"을 지키려고. 골격 `MainActivity`에는 설정 채널이 없고, 만들려면 강민준 폴더(`android/`)를 고쳐야 한다. `app_settings` 9.0.1은 1단계 앱과 같은 `ACTION_APPLICATION_DETAILS_SETTINGS`를 쓰고 추가 권한이 없다(플러그인 매니페스트 비어 있음), MIT |
| image_picker 잔여 파일을 어떻게 골라 지우나 | 앱 `cache/` 바로 아래 파일 중 이름이 UUID + 숫자 + 이미지 확장자인 것만. 에뮬레이터에서 본 실제 이름(`c38ef0c0-…-6a2c5814f4592424015850821494502.jpg`) 모양이다. 다른 이름·하위 폴더는 건드리지 않는다(시험으로 확인) |
| 그 정리가 PC 시험 중 PC 파일을 지우지는 않나 | 캐시 위치를 "임시 폴더 옆 `cache`"로 계산하는데, PC에서는 그곳이 앱 폴더가 아니다. 그래서 image_picker 정리는 **Android에서만** 켜진다. 시험에서는 임시 폴더를 넘겨서 켠다 |
| 계약의 어느 줄을 지키나 | 규격 3장 공통규칙 1(예외 없음 — 세 메서드 모두 안에서 잡는다), 4.3 #4(앱 복사본만 지운다, 설정 화면이 열린다), 검토 결론 1-1 ①(앱 복사본) |
| 시험이 확인하지 않는 것 | 실제 설정 화면이 열리는지(에뮬레이터에서 확인), 앱이 카메라 중에 종료됐다 돌아올 때 `clearLeftovers`가 촬영 중 파일을 먼저 지우는 경우(image_picker `retrieveLostData`와 함께 정할 일) |

## 4. 고친 것

- 처음 만든 bootstrap 주석의 날짜가 틀려(11/14) 11/13으로 고침.
- 결과: `flutter analyze` 0건, `flutter test` 102건 통과 (91 + 새로 11). Windows에서 실행.

## 4-1. 에뮬레이터 확인 (11/13, Android 36 에뮬레이터)

흐름에 아직 카메라 화면이 없어, 커밋하지 않는 임시 진입점 `tool/cleanup_check.dart`(TAKE·RELEASE·CLEAR·SETTINGS 버튼, `sg_` 폴더와 `cache/` 파일 목록 표시)로 확인했다. 앱을 지우고 새로 설치한 깨끗한 상태에서 시작했다. 버튼은 내가 직접 눌렀다.

| 확인 | 결과 |
|---|---|
| 시작 | `sg_` 0개, `cache` 파일 0개 |
| TAKE → 셔터 → ✕(취소) | `cancelled`, `cache`에 0바이트 파일 1개 |
| TAKE → 셔터 → ✓ | `ok`, `sg_` 1개 |
| CLEAR (`clearLeftovers`) | `sg_` 0개, `cache` 파일 0개 |
| SETTINGS (`openAppSettings`) | 기기의 앱 정보 화면이 열림, 뒤로 가기로 복귀 |
| 확인 뒤 `adb run-as`로 앱 폴더 | `cache/` 비어 있음, `code_cache/`에는 Flutter 엔진 폴더만. 비정상 종료 0건 |

참고: 이번 설치본에는 매니페스트에 `CAMERA`가 없어 카메라가 권한 창 없이 열렸다(원래 소스 그대로).

## 5. 남은 것

- 카메라 권한 매니페스트 선언과 `kotlin.incremental=false`는 강민준 요청 그대로 (`2026-11-12_camera-input.md` 5장).
- 권한 안내 화면(DENY)의 "설정으로 이동" 버튼과의 연결은 지형주 화면 쪽. 흐름의 `settingsOpenPermission` 핸들러가 이 메서드를 부르면 된다.
- 앱이 카메라 사용 중 종료됐다가 돌아오는 경우(`retrieveLostData`)는 여전히 다루지 않았다.
