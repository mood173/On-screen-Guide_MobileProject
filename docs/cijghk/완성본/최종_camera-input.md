# 최종 · CameraInput (기기 기본 카메라로 사진 한 장)

2026-11-13 · 최정혁 · PR #3 (`feat/camera-input`)
작업 기록: `../ai_log/2026-11-12_camera-input.md` · 설계: `../데이터_입출력_설계.md` 4-1·4-2

## 하는 일

사용자가 카메라를 고르면 **기기 기본 카메라 앱**을 띄워 한 장을 찍고, 그 사진을 앱 임시 폴더의 복사본(`sg_` 폴더)으로 만들어 경로를 돌려준다. 이 경로가 분석 요청의 `imagePath`로 그대로 간다. 앱 안 촬영 화면(C)은 만들지 않는다(검토 결론 13장 X2).

## 쓰는 법

| 항목 | 내용 |
|---|---|
| 포트 | `CameraInput.takePhoto()` → `PickedImage { status, path, input: camera }` |
| 구현 | `lib/features/capture/data/picker_camera_input.dart` — `PickerCameraInput` (`image_picker`) |
| 조립 | `app/bootstrap.dart`: `cameraInput: PickerCameraInput()` |
| 부르는 곳 | 흐름의 `captureCamera`·`captureRetake` 핸들러 (지형주, 아직 연결 전) |

## 결과

| 상황 | `status` | `path` |
|---|---|---|
| 촬영 성공 | `ok` | 앱 복사본 경로 |
| 카메라를 닫음 | `cancelled` | 없음 |
| 카메라 권한 거부 (`camera_access_denied`, `…_without_prompt`) | `permissionDenied` | 없음 |
| 파일 없음·빈 파일·복사 실패·그 밖의 오류 | `readFailed` | 없음 |

예외를 밖으로 던지지 않는다. 위치 메타데이터를 요청하지 않는다(`requestFullMetadata: false`). image_picker가 앱 캐시에 남긴 촬영 원본은 복사 뒤 지운다(앱 데이터 폴더 안의 파일일 때만).

## 확인

- 시험: 단위 11건 + 앱 복사본 도구 9건 + 공용 시험 2건. `flutter analyze` 0건.
- Android 36 에뮬레이터: 촬영 `ok`, 복사본 해제, 취소 `cancelled`, 권한 거부 `permissionDenied`. 비정상 종료 0건. **실기기 미확인.**
- 권한 거부는 매니페스트에 `CAMERA`를 임시로 넣은 빌드로 확인했다.

## 한계와 남은 것

- 매니페스트 `CAMERA` 선언이 소스에 없다(강민준 요청). 선언 전에는 실제 앱에서 `permissionDenied`가 나오지 않는다.
- 취소하면 image_picker가 만든 0바이트 파일이 앱 캐시에 남는다 → `InputCleanup.clearLeftovers`가 지운다(`최종_input-cleanup.md`).
- 카메라 사용 중 앱이 종료됐다 돌아오는 경우(`retrieveLostData`)는 다루지 않는다.
- Windows에서 프로젝트와 Pub 캐시가 다른 드라이브면 `image_picker_android` Kotlin 컴파일이 실패한다 → `android/gradle.properties`에 `kotlin.incremental=false` (강민준 요청).
