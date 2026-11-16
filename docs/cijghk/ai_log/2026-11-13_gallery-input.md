# GalleryInput (기기 사진 보관함) — 2026-11-13

브랜치: `feat/camera-input` (PR #3에 이어서) · 도구: Claude Code (Opus 5.5)
기준: `협업규격_최종` 3.1·3.2·4.3 #3, `기능별_검토_결론` 1-1(①⑤⑥ 앱 복사본·앨범 선택 없음·최근 9장, ④ 스크린샷 배지), 1-3(Android 14 일부 허용은 ok), 13장 X3·X4, `docs/cijghk/데이터_입출력_설계.md` 4-4

## 1. 맡긴 일

`GalleryInput`의 진짜 구현: 사진 접근 권한, 최근 9장(썸네일·스크린샷 배지·촬영 시각), 고른 한 장을 앱 복사본으로. 예외 없음, 위치 메타데이터 요청 안 함, 사용자 원본 수정·삭제 안 함.

## 2. 받은 구조

| 파일 | 하는 일 |
|---|---|
| `lib/features/capture/data/media_gallery_input.dart` | `MediaGalleryInput`(포트 구현), `MediaLibrary`(사진 보관함 접근, 내부 도구), `PhotoManagerLibrary`(`photo_manager` 3.12) |
| `lib/features/capture/data/app_copy_files.dart` | `saveBytes` 추가 — 갤러리 원본은 파일 경로 대신 바이트로 받아 `sg_` 폴더에 저장. 이름은 영문·숫자·`._-`만 남긴다 |
| `test/features/capture/data/media_gallery_input_test.dart` | 시험 7건 |
| `test/support/fake_media_library.dart` | 시험용 사진 보관함 |
| `test/ports/gallery_input_contract_test.dart` | 공용 시험 `galleryInputContract`에 진짜 구현 2건(허용·거부) |
| `lib/app/bootstrap.dart` | `galleryInput` 줄: **실제 분석기 모드(`FAKE_ANALYZER=false`)일 때만 진짜**, 가짜 분석기 모드는 샘플 갤러리 그대로 |
| `pubspec.yaml` | `photo_manager: ^3.12.0` 추가 (Apache-2.0) |

## 3. 하나씩 물어본 것

| 물어본 것 | AI의 설명 |
|---|---|
| 왜 `photo_manager`인가 | `image_picker`는 시스템 선택기만 열고 목록을 주지 않는다. 앱이 최근 9장을 직접 그리기로 했으므로(검토 결론 1-1) 목록·썸네일·저장 폴더를 주는 패키지가 필요하다 |
| 위치 정보는 | 권한 요청 옵션에 `mediaLocation: false` — `ACCESS_MEDIA_LOCATION`을 요청하지 않는다. 플러그인 매니페스트도 `READ_EXTERNAL_STORAGE`(API 32 이하)만 선언한다 |
| 스크린샷 배지는 어떻게 | `MediaStore.RELATIVE_PATH`에 `Screenshots` 폴더가 있으면 스크린샷. 폴더 이름 전체가 같을 때만(`MyScreenshotsBackup`은 아님). 관례라 기기마다 틀릴 수 있다 |
| 원본을 왜 바이트로 받나 | 원본 파일 경로를 돌려받으면 Android 버전에 따라 패키지가 캐시 복사본을 만들 수 있다. 바이트를 받아 바로 `sg_` 폴더에 쓰면 앱이 만든 파일은 그 복사본 하나뿐이고, 기존 정리 코드로 지워진다 |
| bootstrap을 왜 조건부로 | 가짜 분석기는 샘플 파일 이름으로 정답을 찾는다. 갤러리만 진짜로 바꾸면 에뮬레이터 사진에는 정답이 없어 팀원의 체험 흐름(갤러리 → 분석 → 안내)이 멈춘다. 실제 분석기가 기본이 되면 항상 진짜로 바꾼다 |
| 권한이 없을 때 목록은 | 권한을 묻지 않고 빈 목록. 권한 요청은 `requestAccess`에서만 |
| 계약의 어느 줄을 지키나 | 규격 3장 공통규칙 1(예외 없음), 3.2 `GalleryItem`·`PickedImage`, 4.3 #3(허용 → 목록 → 선택 → 경로, 거부 → `permissionDenied`) |

## 4. 고친 것

- 시험용 사진 보관함을 처음에 시험 파일 안에 두고 다른 시험이 그 파일을 import했다 → `test/support/`로 옮김.
- `flutter analyze` 0건, `flutter test` 149건 통과 (기능 맵까지 136 + 갤러리 13: 단위 7, 공용 시험 6).

## 4-1. 에뮬레이터 확인 (11/13, Android 36 에뮬레이터)

흐름의 갤러리 화면은 아직 가짜 갤러리를 쓰므로, 커밋하지 않는 임시 진입점(ACCESS·RECENT·사진 누르기·RELEASE·MAP)으로 확인했다. Android 13 이상은 매니페스트에 `READ_MEDIA_IMAGES`가 있어야 해서 **임시로 넣고 빌드한 뒤 바로 되돌렸다**(`android/` 변경 없음). 갤러리에는 시험용 사진 4장(스크린샷 폴더 1장, 카메라 폴더 1장, 기존 2장)을 넣었다.

| 확인 | 결과 |
|---|---|
| 권한 허용 전 RECENT | `0장` |
| ACCESS → "Allow all" | `ok` (사용자가 직접) |
| RECENT | 4장, 썸네일 표시, 스크린샷 배지 1장 (사용자가 직접) |
| 사진 누르기 | `ok`, `input=gallery`, `code_cache/sg_…/sg_01.png`, `exists=true`, `isAppCopy=true` |
| RELEASE | `exists=false` |
| 권한 회수(`pm revoke`) 뒤 ACCESS → "Don't allow" | `permissionDenied`, 이어서 RECENT `0장` |
| 비정상 종료 | 0건 |

권한 창에는 "Allow limited access / Allow all / Don't allow" 세 가지가 나왔다. "일부 허용"은 이번에 확인하지 않았다(코드상 `ok`로 보고 허용된 사진만 목록에 나옴).

## 5. 남은 것

- **매니페스트 권한 선언 (강민준 요청)**: `READ_MEDIA_IMAGES`, `READ_MEDIA_VISUAL_USER_SELECTED`(Android 14 일부 허용). 선언 전에는 Android 13 이상에서 항상 `permissionDenied`.
- "일부 허용(limited)" 경로는 에뮬레이터에서 확인하지 않았다.
- 흐름 연결: `FAKE_ANALYZER=false`이고 지형주의 갤러리 화면이 이 포트를 쓰면 실제 앱에서 끝까지 확인할 수 있다. 지금 실제 분석기는 Kotlin 채널이 계약 형식이 되기 전이라(강민준, 11/20) 분석 단계에서 막힌다.
- 같은 사진을 여러 번 고르면 고를 때마다 복사본이 생긴다. 흐름이 다시 고를 때 `release`, 앱 시작 때 `clearLeftovers`로 지운다(규격 3.4).
