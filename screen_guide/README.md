# 화면길잡이 (screen_guide)

화면 이미지 1장을 기기 안에서 분석해, 원하는 기능까지 누를 위치와 순서를 단계별로 안내하는 Android 앱.
기준 문서: Notion「화면길잡이 개발 계약 v1」, 「제공 기능과 개념 정리」, 「설계 (러프 · 보완판)」,
Figma「화면길잡이 · UI 설계서 v2 · Beta」(대응표: [docs/figma.md](docs/figma.md)).

## 환경

- Flutter **3.47.9** (팀 공통, `C:\dev\flutter`), Android Studio 내장 JDK
- 프로젝트 경로에 한글·공백 금지 (Gradle 빌드 오류)
- 에뮬레이터 저장 공간이 부족하면 설치가 멈추거나 `INSUFFICIENT_STORAGE`가 난다 → Device Manager에서 Wipe Data

```powershell
cd screen_guide
flutter pub get
flutter run                                     # 가짜 분석기(기본값)
flutter run --dart-define=FAKE_ANALYZER=false   # 실제 Kotlin 분석기 (ML Kit 온디바이스)
```

## 시험

```powershell
flutter analyze
flutter test                                        # Dart: 계약 코덱·분석기·흐름·화면 (28건)
cd android; .\gradlew.bat :app:testDebugUnitTest    # Kotlin: GuideLogicTest (28건)
```

`gradlew.bat`은 Git에 넣지 않는 파일이라, 처음 받은 뒤에는 `flutter run` 또는 `flutter build apk`를 한 번 해야 생긴다.

## 지금 되는 것

갤러리 흐름 전체가 Figma 화면대로 동작한다 (가짜 분석기 + 샘플 이미지 2장).

```
H 홈 → G 최근 이미지 → GS 선택 → GR 선택한 이미지 → GA 분석 중 → RG 분석 결과
     → D1~Dn 단계별 안내 → DONE 안내 완료          (실패하면 E 다시 시도)
```

- 샘플: 설정 화면(기능 2개, 1단계), 메시지 화면(기능 1개, 2단계, 개인정보 후보 5건)
- 가짜 분석기의 글자·위치는 샘플을 실제 ML Kit로 분석한 값이라 테두리가 이미지와 맞는다
- 카메라·실시간 스캔·기록·설정·공유 버튼은 "준비 중" 안내만 띄운다

## 구조

```
lib/
  core/          ActionId, ErrorCode, FlowState, ScreenId     ← 계약 (바꾸기 전 팀 방 공지)
  contract/      analysis.dart: 채널 요청·응답 형식           ← 계약 v1 JSON과 1:1
  domain/        포트 (ScreenAnalyzer)
  data/          MethodChannelAnalyzer(진짜) / FakeAnalyzer(가짜), ImageFiles(샘플 → 캐시 파일),
                 sample_images.dart, demo_guidance.dart(체험용 기능 맵, 데이터 담당이 교체)
  runtime/       guide_flow.dart: 현재 화면·상태, Gate(화면별 허용 행동), dispatch
  ui/theme/      Figma 색·글자·모서리·여백, Material 테마
  ui/cell/       GuideScaffold(툴바·버튼), ScreenImage(원본 좌표 → 화면 좌표로 상자 그리기)
  ui/screen/     화면 9종 (홈, 갤러리, 확인, 분석 중, 결과, 단계, 완료, 오류)
  bootstrap.dart 실제/가짜 구현을 고르는 유일한 곳
assets/samples/  체험용 샘플 이미지
android/app/src/main/kotlin/com/screenguide/screen_guide/
  logic/GuideLogic.kt   화면 식별·대상 찾기·개인정보 정규식 (Android 의존 없음)
  Analyzer.kt           ML Kit OCR·개체 추출
  MainActivity.kt       채널 screen_guide/analyze
```

규칙: 화면 위젯은 상태를 받아 그리기만 하고, 버튼은 `flow.dispatch(ActionId.xxx)`만 부른다.
업무 처리와 화면 전환은 `GuideFlow`가 한다.

## 남은 일

| 담당 | 할 일 |
|---|---|
| 팀원 1 (분석·AI) | Kotlin 채널을 계약 v1 형식으로 수정 (`imagePath`·`guidance`·`target` 받기, 응답 JSON, 요청으로 받은 맵 사용), OCR 글자 로그 제거, 정규식 `\b` 결함 수정. 지금 `FAKE_ANALYZER=false`로 돌리면 `NO_PATH`가 나는 것이 이 때문 |
| 팀원 2 (화면·흐름) | G·GS·RG 화면을 Figma 수치와 대조, ActionRegistry, P·SHARE·HISTORY·SETTINGS·DENY·카메라 화면 |
| 팀원 3 (데이터·입출력) | 기능 맵 스키마·GuidanceRepository(체험용 `demo_guidance.dart` 교체), image_picker, 이력 DB, share_plus, Firebase |
| 공통 | release 빌드 시 ML Kit가 코드 축소(R8)로 깨져 시작 즉시 종료됨 → proguard keep 규칙 필요. 계약에 "선택 확정" ActionId 추가 여부 (지금은 `captureGallery` 재사용) |
