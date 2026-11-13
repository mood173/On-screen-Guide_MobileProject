# 최종 · InputCleanup (앱 복사본 정리 · 권한 설정 열기)

2026-11-13 · 최정혁 · PR #3 (`feat/camera-input`)
작업 기록: `ai_log/2026-11-13_input-cleanup.md` · 설계: `데이터_입출력_설계.md` 4-1·4-3

## 하는 일

사진을 가져올 때 생긴 **앱 복사본을 치우고**, 권한을 거부한 사용자를 위해 **기기의 앱 권한 설정 화면을 연다**. 원본 이미지를 앱에 남기지 않는다는 원칙(C03)을 지키는 쪽이다. 사용자 갤러리의 원본은 절대 지우지 않는다.

## 쓰는 법

| 항목 | 내용 |
|---|---|
| 포트 | `InputCleanup.release(image)`, `clearLeftovers()`, `openAppSettings()` |
| 구현 | `lib/features/capture/data/file_input_cleanup.dart` — `FileInputCleanup` (`app_settings` 패키지) |
| 조립 | `app/bootstrap.dart`: `inputCleanup: FileInputCleanup()` |
| 부르는 곳 (규격 3.4) | 앱 시작 → `clearLeftovers` (골격에 연결됨) · 세션이 끝날 때(홈으로·다시 고르기·오류 뒤) → `release` (골격에 연결됨) · 권한 안내 화면의 설정 버튼 → `openAppSettings` (지형주, `settingsOpenPermission`) |

## 동작

| 메서드 | 지우는 것 / 하는 것 | 건드리지 않는 것 |
|---|---|---|
| `release` | 그 결과의 `sg_` 복사본 폴더 | 사용자 원본, 경로 없는 결과 |
| `clearLeftovers` | 임시 폴더 바로 아래 `sg_*` 폴더 전부 + 앱 `cache/` 바로 아래의 image_picker 파일(UUID+숫자+이미지 확장자: 카메라 취소 때의 0바이트 파일, 촬영 중 종료된 사진) | 다른 이름의 캐시 파일, 하위 폴더. image_picker 정리는 Android에서만 |
| `openAppSettings` | 앱 정보(권한) 화면 (`ACTION_APPLICATION_DETAILS_SETTINGS`) | — |

세 메서드 모두 예외를 밖으로 던지지 않는다. 설정 화면은 Kotlin 채널 대신 패키지로 연다(규격 2장 "Kotlin을 부르는 Dart 코드는 `MethodChannelAnalyzer` 하나뿐").

## 확인

- 시험: 단위 10건 + 공용 시험 1건.
- Android 36 에뮬레이터: 카메라 취소로 생긴 0바이트 파일과 `sg_` 복사본이 `clearLeftovers`로 지워짐, `openAppSettings`로 앱 정보 화면이 열림. 비정상 종료 0건. **실기기 미확인.**

## 한계와 남은 것

- 앱이 카메라 사용 중 종료됐다 돌아오면, 앱 시작 때의 `clearLeftovers`가 `retrieveLostData`로 되찾을 촬영 파일을 먼저 지울 수 있다. `retrieveLostData`를 다루기로 하면 순서를 같이 정한다.
