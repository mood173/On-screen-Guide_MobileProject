# cijghk 인수인계

## 담당 범위

데이터·입출력 (협업규격_최종 4.3): `CameraInput`, `GalleryInput`, `InputCleanup`, 기능 맵 스키마·저장소, `HistoryRepository`, `Sharer`, (선택) `MapUpdater`, CI.
구현 계획은 `데이터_입출력_설계.md`, 작업별 기록은 `ai_log/`에 있다.

## 변경·검증 기록

### 2026-11-12~13 · `CameraInput` (브랜치 `feat/camera-input`)

- 변경: `screen_guide/lib/features/capture/data/picker_camera_input.dart`, `app_copy_files.dart`(새 파일), `lib/app/bootstrap.dart`(카메라 줄), `pubspec.yaml`(`image_picker` 추가), 시험 3개 파일.
- 검증: `flutter analyze` 0건, `flutter test` 91건 통과(Windows). Android 36 **에뮬레이터**에서 촬영 `ok`·복사본 해제·취소 `cancelled`·권한 거부 `permissionDenied` 확인. 실기기 확인은 하지 않았다.
- 권한 거부는 매니페스트에 `CAMERA`를 임시로 넣은 빌드로 확인했다(소스에는 넣지 않음).
- 남은 확인·요청: `ai_log/2026-11-12_camera-input.md` 5장 (매니페스트 `CAMERA` 선언과 `kotlin.incremental=false`는 강민준에게 요청, 취소 때 남는 0바이트 파일은 `InputCleanup`에서 처리, 카메라 화면 연결은 지형주).

### 2026-11-13 · `InputCleanup` (같은 브랜치 `feat/camera-input`)

- 변경: `screen_guide/lib/features/capture/data/file_input_cleanup.dart`(새 파일), `lib/app/bootstrap.dart`(정리 줄), `pubspec.yaml`(`app_settings` 추가), 시험 2개 파일.
- 검증: `flutter analyze` 0건, `flutter test` 102건 통과(Windows). Android 36 **에뮬레이터**에서 카메라 취소 때 남은 0바이트 파일·`sg_` 복사본이 `clearLeftovers`로 지워지고, `openAppSettings`로 앱 정보 화면이 열리는 것을 확인. 실기기 확인은 하지 않았다.
- 남은 것: `ai_log/2026-11-13_input-cleanup.md` 5장.

### 2026-11-13 · 기능 맵 스키마 v1 + `AssetGuidanceRepository` (같은 브랜치)

- 변경: `assets/feature_maps/schema_v1.json`·`sample_v1.json`(지금은 체험용 맵과 같은 내용), `lib/features/guidance_map/data/feature_map.dart`·`asset_guidance_repository.dart`, `bootstrap.dart`(guidance 줄), `pubspec.yaml`(에셋), 시험 2개 파일.
- 검증: 맵 시험 34건(단위 28, 공용 6). 에뮬레이터에서 앱 번들의 맵을 읽음(revision·화면·기능 확인).
- 남은 것: `ai_log/2026-11-13_feature-map.md` 5장 (실제 앱 맵 내용은 11/27 강민준).

### 2026-11-13 · `GalleryInput` (같은 브랜치)

- 변경: `lib/features/capture/data/media_gallery_input.dart`(새 파일), `app_copy_files.dart`(`saveBytes`), `bootstrap.dart`(갤러리 줄, 실제 분석기 모드에서만 진짜), `pubspec.yaml`(`photo_manager`), 시험 3개 파일.
- 검증: `flutter analyze` 0건, `flutter test` 149건 통과. Android 36 **에뮬레이터**에서 권한 허용·목록 4장·스크린샷 배지·한 장 고르기·해제·권한 거부 확인 (매니페스트 권한은 임시로 넣고 되돌림). 실기기 확인은 하지 않았다.
- 남은 것: `ai_log/2026-11-13_gallery-input.md` 5장 (매니페스트 `READ_MEDIA_IMAGES` 선언은 강민준 요청).
