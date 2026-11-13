# 최종 · GalleryInput (기기 사진 보관함에서 한 장)

2026-11-13 · 최정혁 · PR #3 (`feat/camera-input`)
작업 기록: `ai_log/2026-11-13_gallery-input.md` · 설계: `데이터_입출력_설계.md` 4-1·4-4

## 하는 일

앱이 직접 그리는 갤러리 화면(G·GS)에 **최근 사진·스크린샷 9장**을 주고, 사용자가 고른 한 장을 앱 복사본(`sg_` 폴더)으로 만들어 경로를 돌려준다. 앨범 선택과 더 불러오기는 없다(검토 결론 13장 X3·X4).

## 쓰는 법

| 항목 | 내용 |
|---|---|
| 포트 | `GalleryInput.requestAccess()` → `ok`/`permissionDenied` · `recent({limit = 9})` → `List<GalleryItem>` · `use(id)` → `PickedImage { input: gallery }` |
| 구현 | `lib/features/capture/data/media_gallery_input.dart` — `MediaGalleryInput` (`photo_manager` 3.12) |
| 조립 | `app/bootstrap.dart`: **`FAKE_ANALYZER=false`일 때만** `MediaGalleryInput()`, 가짜 분석기 모드는 `FakeGalleryInput`(샘플) |
| 부르는 곳 | 흐름의 `captureGallery`·`capturePick`·`captureConfirm` 핸들러 (지형주) |

bootstrap을 조건부로 둔 이유: 가짜 분석기는 샘플 파일 이름으로 정답을 찾는다. 갤러리만 진짜로 바꾸면 기기 사진에는 정답이 없어 지금의 체험 흐름이 멈춘다. 실제 분석기가 기본이 되면 항상 진짜로 바꾼다.

## 동작

| 메서드 | 결과 |
|---|---|
| `requestAccess` | 허용(일부 허용 포함) → `ok`, 거부·오류 → `permissionDenied`. 위치 메타데이터 권한은 요청하지 않음(`mediaLocation: false`) |
| `recent` | 최근 것부터 최대 `limit`장: 썸네일(240px), 촬영 시각, 저장 폴더에 `Screenshots`가 있으면 스크린샷 배지. 권한이 없거나 오류면 빈 목록 |
| `use` | 원본을 바이트로 읽어 `sg_` 폴더에 저장 → `ok` + 경로. 모르는 id·빈 사진·오류 → `readFailed` |

예외를 밖으로 던지지 않는다. 사용자 원본은 읽기만 한다.

## 확인

- 시험: 단위 7건 + 공용 시험 6건.
- Android 36 에뮬레이터: 권한 허용 → 목록 4장·스크린샷 배지 1장 → 한 장 고르기 `ok`(복사본 존재) → 해제, 권한 거부 → `permissionDenied`·빈 목록. 비정상 종료 0건. **실기기 미확인.**
- 매니페스트 권한은 임시로 넣은 빌드로 확인했다.

## 한계와 남은 것

- 매니페스트에 `READ_MEDIA_IMAGES`, `READ_MEDIA_VISUAL_USER_SELECTED` 선언이 없다(강민준 요청). 선언 전에는 Android 13 이상에서 항상 `permissionDenied`.
- "일부 사진만 허용"은 에뮬레이터에서 확인하지 않았다(코드상 `ok`, 허용된 사진만 목록에 나옴).
- 스크린샷 판단은 저장 폴더 이름 관례라 기기에 따라 틀릴 수 있다(배지만 달라짐).
