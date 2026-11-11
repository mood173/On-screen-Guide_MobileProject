# 화면길잡이 · 사진 인식 앱 2107 MP2 (온디바이스 분석)

MP1의 카메라·갤러리 입력 화면에 기기 안에서 도는 한국어 글자 인식을 연결한 Android Flutter 앱입니다. 이미지를 고른 뒤 **이미지 분석하기**를 누르면 인식된 줄과 처리 시간이 화면에 나옵니다.

## 선택한 분석 기능과 라이브러리

- 분석 기능: 이미지 속 글자 인식(OCR), 한국어·영문
- 라이브러리: Google ML Kit Text Recognition v2 한국어 모델 (`com.google.mlkit:text-recognition-korean:16.0.1`)
- 모델이 앱에 함께 들어가는 번들 방식이라 실행 중에 모델을 내려받지 않습니다. 그래서 비행기 모드에서도 동작합니다.
- 호출 경로: Flutter `lib/main.dart` → MethodChannel `screen_guide/analyze`의 `analyzeOcr` → Kotlin `MainActivity.kt` → `Analyzer.kt` → ML Kit → 줄 목록·상태·처리 시간 반환

## 처리 시간 측정값

2026-11-10 Android 에뮬레이터(`Resizable_Experimental`)에서 직접 실행한 값입니다.

| 입력 | 네트워크 | 결과 | 처리 시간 | 스크린샷 |
|---|---|---|---|---|
| 앱 화면 캡처 이미지 | 연결됨 | 6줄 인식 | 989ms | `screenshots/01_ocr_result_online.png` |
| 같은 이미지 | 비행기 모드 | 6줄 인식 | 1077ms | `screenshots/02_ocr_airplane_mode.png` |
| 흰색 600×800 PNG | 비행기 모드 | 0줄 (안내 표시) | 70ms | `screenshots/03_no_text_guidance.png` |

- 측정 구간: `Analyzer.kt`에서 이미지 디코딩을 시작할 때부터 OCR 성공 콜백까지, `SystemClock.elapsedRealtime()` 차이
- 각 1회 실행한 값입니다. 기기와 이미지에 따라 달라집니다.
- 비행기 모드는 `adb shell cmd connectivity airplane-mode enable`로 켰습니다.

## 인식 불가 처리 방식

| 상황 | 처리 |
|---|---|
| 글자가 한 줄도 없음 | 오류가 아니라 정상 결과로 봅니다. 상태 `no_text`를 돌려주고 화면에 "글자를 찾지 못했어요"와 다시 촬영·선택 안내, **같은 이미지 다시 분석**·**다른 이미지 선택** 버튼을 보여 줍니다. |
| 파일을 읽지 못함 | "이미지를 가져오지 못했어요. 다시 시도해 주세요." 안내를 보여 줍니다. |
| OCR 실행 실패 | "분석을 완료하지 못했어요. 다시 시도해 주세요." 안내를 보여 줍니다. |
| 사진 선택 취소, 카메라 권한 거부 | MP1과 같습니다. 취소는 원래 화면에 머물고, 거부는 안내 화면으로 갑니다. |

## 실행 절차

1. Flutter와 Android SDK가 설치된 환경에서 Android 기기 또는 에뮬레이터를 연결합니다.
2. `app/` 폴더에서 `flutter pub get`, 이어서 `flutter run`을 실행합니다.
3. 홈에서 카메라 촬영 또는 갤러리 선택 → 미리보기 → **선택한 이미지 사용** → **이미지 분석하기** 순서로 진행합니다.
4. 비행기 모드 확인: 기기의 비행기 모드를 켠 뒤 3번을 다시 합니다.

실제 휴대전화 카메라로 찍은 사진의 인식 품질은 따로 확인하지 않았습니다.
