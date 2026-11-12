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
