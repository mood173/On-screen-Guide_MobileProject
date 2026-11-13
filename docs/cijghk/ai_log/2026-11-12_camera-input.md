# CameraInput (기기 기본 카메라) — 2026-11-12

브랜치: `feat/camera-input` · 도구: Claude Code (Opus 5.5)
기준: `협업규격_최종` 3.1·4.3 #2, `기능별_검토_결론` 1장·13장, `docs/cijghk/데이터_입출력_설계.md` 4장

## 1. 맡긴 일

`CameraInput`의 진짜 구현을 만들어 공용 시험을 통과시키고 `bootstrap`의 카메라 줄을 바꾼다.
조건: 기본 카메라 앱(`image_picker`), 결과 네 가지(`ok`/`cancelled`/`permissionDenied`/`readFailed`), 예외를 던지지 않음,
앱 복사본(`sg_` 폴더)의 경로를 돌려줌, 사용자 원본은 지우지 않음. 1단계 앱의 `_handlePickerError` 논리를 옮긴다.

## 2. 받은 구조

| 파일 | 하는 일 |
|---|---|
| `lib/features/capture/data/app_copy_files.dart` | 앱 복사본 도구 (포트 아님). `copyFrom`(원본 → `sg_` 폴더 복사, 없거나 빈 파일이면 예외), `isAppCopy`(임시 폴더 바로 아래 `sg_*` 안의 파일인가), `isInsideAppData`(앱 데이터 폴더 아래인가), `release`, `clearLeftovers` |
| `lib/features/capture/data/picker_camera_input.dart` | `PickerCameraInput`. 촬영 함수를 받아(기본값 = `ImagePicker().pickImage(camera, requestFullMetadata: false)`) 결과를 `PickedImage`로 바꾼다 |
| `test/features/capture/data/*_test.dart` | 위 두 파일의 시험 (카메라 11건, 복사본 9건) |
| `test/ports/camera_input_contract_test.dart` | 공용 시험 `cameraInputContract`에 진짜 구현 2건(성공·취소) |
| `lib/app/bootstrap.dart` | 카메라 줄만 `PickerCameraInput()`으로 교체, 표 주석 갱신 |
| `pubspec.yaml`, `pubspec.lock` | `image_picker: ^1.2.4` 추가 (공용 파일 — PR에 적고 팀에 알림) |

처리 순서 (`takePhoto`):
1. 촬영 함수 호출. `PlatformException` → 코드가 권한 거부면 `permissionDenied`, 아니면 `readFailed`. 그 밖의 예외 → `readFailed`
2. `null`이면 `cancelled`
3. 촬영 파일을 `sg_` 폴더로 복사 → `ok` + 복사본 경로. 복사 실패 → `readFailed`
4. 어느 경우든 image_picker가 남긴 촬영 파일을 지운다 — 단, 앱 데이터 폴더 안일 때만

## 3. 하나씩 물어본 것

| 물어본 것 | AI의 설명 |
|---|---|
| 계약의 어느 줄을 지키나 | 규격 3장 공통규칙 1(예외 없음), 3.2 `PickStatus` 네 값, 4.3 #2 완료 기준(네 결과가 각각 다름), 검토 결론 1-1 ①(앱 복사본 경로) ②(기본 카메라 앱) |
| 왜 촬영 파일을 바로 쓰지 않고 복사하나 | 갤러리와 같은 `sg_` 규칙으로 두면 `InputCleanup`이 한 가지 방법으로 지울 수 있다. 골격의 가짜 정리(`CacheImageFiles`)도 같은 위치·접두사라 지금 bootstrap 그대로도 복사본이 지워진다 |
| 촬영 파일을 지우는 게 사용자 원본을 지우는 것은 아닌가 | image_picker는 촬영 결과를 앱 캐시에 만든다(갤러리에 저장하지 않음). 그래도 안전장치로 "임시 폴더의 상위 = 앱 데이터 폴더" 아래일 때만 지운다. 밖의 파일은 시험으로 안 지우는 것을 확인. 에뮬레이터에서 촬영 파일이 앱 `cache/` 아래에 생기는 것도 확인함 (4-1) |
| 권한 거부 코드는 어디서 왔나 | 1단계 앱 `_handlePickerError`의 `camera_access_denied`, `camera_access_denied_without_prompt`. `photo_access_denied`는 갤러리용이라 카메라에서는 `readFailed` |
| 원본·글자가 로그로 나가는 곳 | 이 코드에는 로그가 없다. 경로만 돌려준다 |
| 시험이 확인하지 않는 것 | 실제 카메라 앱 실행, 권한 대화상자, 앱이 카메라 중에 종료됐다 돌아오는 경우(image_picker `retrieveLostData`). 아래 5장 참고 |

## 4. 고친 것

- `clearLeftovers` 시험이 Windows에서 실패: 경로 구분자(`/`와 `\`)가 섞여 비교가 틀림 → 폴더 이름만 비교하도록 시험을 고침. 코드 결함이 아니었다.
- lint `prefer_initializing_formals` 1건 → 골격 `fake_input.dart`와 같이 파일 위 `ignore_for_file`로.
- 결과: `flutter analyze` 0건, `flutter test` 90건 통과 (기존 69 + 새로 21, 이후 4-2에서 1건 추가). Windows에서 실행.

## 4-1. 에뮬레이터 확인 (11/12, Android 36 에뮬레이터 · 후면 카메라 emulated)

화면 흐름에는 아직 카메라 버튼이 연결되지 않아(골격에서 "준비 중"), 커밋하지 않는 임시 진입점 `tool/camera_check.dart`(버튼 하나로 `PickerCameraInput().takePhoto()` 호출, 결과 표시)로 확인했다.

| 확인 | 결과 |
|---|---|
| TAKE → 기본 카메라 앱(`com.android.camera2`)이 열림 | 확인 |
| 셔터 → `status=ok`, `input=camera`, 경로 `/data/user/0/com.screenguide.screen_guide/code_cache/sg_NUYNVB/<uuid>.jpg`, 파일 있음, 화면에 사진 표시 | 확인 |
| image_picker가 `cache/`에 만든 촬영 원본은 지워지고 `sg_` 복사본 하나만 남음 (`run-as … find cache code_cache`) | 확인 |
| RELEASE → `sg_` 폴더 삭제, `code_cache`에는 Flutter 엔진 폴더만 | 확인 |
| 카메라 앱에서 뒤로 → `status=cancelled`, `path=null` | 확인 |
| 권한 거부 → `permissionDenied` | 확인 (2차, 아래) |

**2차 확인 (11/12, 내가 에뮬레이터를 직접 조작, Claude는 `adb`로 앱 폴더만 확인).** 1차 확인 중 다른 작업이 같은 에뮬레이터를 건드려 결과가 섞였으므로 다시 확인했다. 설치된 앱은 1차의 임시 빌드(매니페스트에 `CAMERA` 임시 추가, 소스는 되돌림)다. Dart 코드는 지금 브랜치와 같다.

| 확인 | 결과 |
|---|---|
| TAKE → 셔터 → ✓ | `status=ok`, `code_cache/sg_KKCQJD/<uuid>.jpg`, `exists=true`, `isAppCopy=true` |
| 촬영 중 `cache/`의 image_picker 파일 | 촬영이 끝나면 지워짐 (`cache/` 비어 있음) |
| RELEASE | `released → exists=false`, `sg_KKCQJD` 폴더 없음 |
| TAKE → 카메라에서 뒤로 | `status=cancelled`. **`cache/`에 0바이트 jpg가 남음** (14:43) — 재현됨 |
| `pm revoke … CAMERA` 뒤 TAKE 2회 | 두 번 모두 `status=permissionDenied` |

정정: 1차 기록 뒤 `cache/`에서 본 0바이트 파일 하나는 취소 흔적이 아니라 **카메라가 열려 있는 동안** image_picker가 만들어 둔 파일이었다(복사본과 이름이 같았다). 취소 때 0바이트가 남는 것은 2차에서 다시 확인했다.

새로 발견: **취소하면 image_picker가 미리 만든 0바이트 파일이 `cache/`에 남는다** (`cache/<uuid>.jpg`, 0 bytes). 사진 내용은 없지만 쌓인다. 촬영 함수가 null을 돌려줘서 이 구현은 그 경로를 모른다 → `InputCleanup.clearLeftovers`에서 앱 `cache/`의 image_picker 잔여 파일도 정리하도록 다음 작업에서 정한다. **(11/13 처리함: `FileInputCleanup`, `2026-11-13_input-cleanup.md`)**

권한 거부 시험 경과: 매니페스트에 `CAMERA`를 **임시로** 넣고(시험 뒤 되돌림, 커밋 안 함) 다시 빌드·설치.
1차: 앱 시작 시 `IllegalStateException: MlKitContext has not been initialized` (`MainActivity.kt:13` → `Analyzer.kt:22`, 강민준 코드)로 비정상 종료. 병합 매니페스트에는 `MlKitInitProvider`가 있었다. 덮어 설치(`install -r`) 직후 에뮬레이터 시스템 서비스가 잠시 응답하지 않던 때였다.
2차: 다시 설치하자 비정상 종료는 0건이었지만, 에뮬레이터 부하(load average 15.7)로 앱 화면이 검은 채 진행되지 않음.
→ 원인 미확정. 내 카메라 코드와는 다른 경로(앱 시작 시 Kotlin ML Kit 초기화)라 보고 후 판단하기로 함 (공통 지침: 두 번 시도 후 보고).

## 4-2. 다시 읽고 고친 것 (11/13, push 전 점검)

- `AppCopyFiles._fileName`이 `/`처럼 이름이 없는 경로에서 `StateError`를 던질 수 있었다 → `release`가 예외를 밖으로 낼 수 있어 계약(예외 없음)에 어긋남. 빈 문자열을 돌려주게 고치고 시험 1건 추가.
- 이미 확인한 `[확인 필요]` 주석 정리 (`picker_camera_input.dart`).
- `flutter analyze` 0건, `flutter test` 91건 통과.

## 5. 남은 것

- **빌드 참고 (Windows)**: 프로젝트 폴더와 Pub 캐시가 **서로 다른 드라이브**에 있으면 `image_picker_android:compileDebugKotlin`이 "different roots" 오류로 실패한다(Kotlin 증분 컴파일 문제). 1단계 앱처럼 `screen_guide/android/gradle.properties`에 `kotlin.incremental=false` 한 줄이면 해결된다 — `android/`는 강민준 담당이라 요청. 그전까지는 각자 Pub 캐시를 프로젝트와 같은 드라이브에 두면 된다.
- 프로젝트가 NDK 28.2.13676358을 요구한다. 없으면 첫 빌드 때 Gradle이 내려받으므로 SDK가 있는 드라이브에 공간이 필요하다.
- 권한 거부는 임시 빌드(매니페스트에 CAMERA 임시 추가)로 확인했다. 실제 앱에서 나오게 하려면 아래 매니페스트 선언이 필요하다.
- **카메라 권한 매니페스트 선언**: 강민준에게 요청 필요 (`screen_guide/android/app/src/main/AndroidManifest.xml`에 `android.permission.CAMERA`). 선언 전에는 `permissionDenied`가 나오지 않는다.
- 화면 쪽: 지금 골격에서 카메라 버튼은 "준비 중"이라 흐름이 `CameraInput`을 아직 부르지 않는다. 앱에서 끝까지 확인하려면 지형주의 카메라 화면(CP·CR)이 필요하다.
- 카메라 앱 사용 중 앱이 종료됐다가 돌아오는 경우(`retrieveLostData`)는 다루지 않았다. 포트가 한 번 호출에 한 결과를 주는 모양이라 흐름과 함께 정해야 한다.
- 기능별_검토_결론 13장 X2(앱 안 촬영 화면) 확인함 — 만들지 않았다.
