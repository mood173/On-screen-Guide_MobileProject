# 화면길잡이 · 사진 인식 앱 2107 MP2

MP1의 카메라·갤러리 입력 화면에 한국어 ML Kit 글자 인식을 연결한 Android Flutter 앱입니다. 이미지를 선택해 표시한 다음 **이미지 분석하기**를 누르면 인식된 줄과 처리 시간이 화면에 나옵니다. 글자가 없으면 오류 대신 촬영·선택 안내가 나옵니다.

## 실행

Flutter와 Android SDK를 설치하고 Android 기기 또는 에뮬레이터를 연결한 뒤 `flutter pub get`, `flutter run`을 실행합니다. 홈에서 카메라 촬영 또는 갤러리 선택 → 이미지 미리보기 → 선택한 이미지 사용 → 이미지 분석하기 순서로 진행합니다.

## 구현과 예외

- `lib/main.dart`의 MP1 이미지 입력 경로를 유지하고 `screen_guide/analyze` MethodChannel의 `analyzeOcr`를 호출합니다.
- `MainActivity.kt`가 파일 경로를 `Analyzer.kt`에 전달합니다. `Analyzer.kt`의 한국어 ML Kit Text Recognition이 기기 안에서 OCR을 수행하고 줄 목록·상태·처리 시간(ms)을 반환합니다. 이 경로에서는 네트워크 모델 다운로드와 기존 개체 추출 코드를 호출하지 않습니다.
- 인식된 줄이 0개면 `no_text`로 반환해 “글자를 찾지 못했어요”와 다시 촬영·선택 안내를 보여 줍니다. 빈 이미지는 정상 처리입니다.
- 사용자가 사진 선택을 취소하면 기존 화면에 머물고, 권한 거부는 안내 화면과 설정 이동으로 처리합니다. 파일을 읽지 못하거나 OCR이 실패하면 재시도 안내를 보여 줍니다.

## 실제 실행 확인 (Android 에뮬레이터)

2026-11-10 `Resizable_Experimental` Android 에뮬레이터에서 직접 실행했습니다. 동일한 화면 캡처 이미지를 일반 연결 상태에서 분석해 **6줄, 989ms**, `adb shell cmd connectivity airplane-mode enable`로 비행기 모드를 켠 뒤 분석해 **6줄, 1077ms**가 표시됐습니다. 흰색 600×800 PNG는 **0줄, 70ms**로 오류 없이 안내 화면이 표시됐습니다. 처리 시간은 `SystemClock.elapsedRealtime()`로 이미지 디코딩 시작부터 OCR 성공 콜백까지 측정한 단일 실행값이며, 기기·입력 이미지마다 달라집니다. 스크린샷은 `screenshots/`에 있습니다. 실제 휴대전화에서의 촬영 품질은 별도 확인이 필요합니다.

## 제출

ZIP 최상위: `app/`(실행 소스), `README.md`, `screenshots/`, `prompts_log.md`. `.env`, `.dart_tool`, `build`, `.gradle` 등 생성·비밀 파일은 제외합니다.
