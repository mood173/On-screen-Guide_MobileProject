# 화면길잡이 (screen_guide)

화면 이미지 1장을 기기 안에서 분석해, 원하는 기능까지 누를 위치와 순서를 단계별로 안내하는 Android 앱.
기준 문서: Notion「화면길잡이 개발 계약 v1」, 「제공 기능과 개념 정리」, 「설계 (러프 · 보완판)」.

## 환경

- Flutter **3.47.9** (팀 공통, `C:\dev\flutter`), Android Studio 내장 JDK
- 프로젝트 경로에 한글·공백 금지 (Gradle 빌드 오류)

```powershell
cd screen_guide
flutter pub get
flutter run                              # 가짜 분석기(기본값)
flutter run --dart-define=FAKE_ANALYZER=false   # 실제 Kotlin 분석기
```

## 시험

```powershell
flutter analyze
flutter test                              # Dart: 계약 코덱·분석기
cd android; .\gradlew.bat :app:testDebugUnitTest   # Kotlin: GuideLogicTest
```

## 구조

```
lib/
  core/        ActionId, ErrorCode, FlowState         ← 계약 (바꾸기 전 팀 방 공지)
  contract/    analysis.dart: 채널 요청·응답 형식     ← 계약 v1 JSON과 1:1
  domain/      포트 (ScreenAnalyzer …)
  data/        구현체 (MethodChannelAnalyzer, FakeAnalyzer …)
  bootstrap.dart  실제/가짜 구현을 고르는 유일한 곳
android/app/src/main/kotlin/com/screenguide/screen_guide/
  logic/GuideLogic.kt   화면 식별·대상 찾기·개인정보 정규식 (Android 의존 없음)
  Analyzer.kt           ML Kit OCR·개체 추출
  MainActivity.kt       채널 screen_guide/analyze
```

## 현재 상태 (골격)

- Kotlin 코드는 `screen_guide_test`에서 패키지명만 바꿔 옮겼다. 채널 응답은 아직 **시험 앱 형식**이라
  `FAKE_ANALYZER=false`로 돌리면 `ANALYSIS_FAILED`가 난다. 계약 v1 형식으로 바꾸는 것은 분석 담당의 첫 작업.
- 정규식 `\b` 결함(GuideLogicTest r03)은 JDK 버전에 따라 드러나지 않을 수 있다. 수정 필요.
- 화면 흐름(GuideSequence·Gate·ActionRegistry), 기능 맵 스키마·저장소는 각 담당이 추가한다.
