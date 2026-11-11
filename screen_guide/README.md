# 화면길잡이 (screen_guide)

팀원: 팀원 1 **강민준** (분석·AI) · 팀원 2 **지형주** (화면·흐름) · 팀원 3 **최정혁** (데이터·입출력)

화면 이미지 1장을 기기 안에서 분석해, 원하는 기능까지 누를 위치와 순서를 단계별로 안내하는 Android 앱.
기준 문서: Notion「화면길잡이 개발 계약 v1」, 「제공 기능과 개념 정리」, 「설계 (러프 · 보완판)」,
Figma「화면길잡이 · UI 설계서 v2 · Beta」(대응표: [docs/figma.md](docs/figma.md)).
**협업 틀·연결 지점·일정: [docs/collaboration_plan.md](docs/collaboration_plan.md)** ← 작업 전에 먼저 읽기

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
flutter test                                        # Dart: 계약·예시 파일·포트 공용 시험·흐름·화면 (47건)
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
  main.dart                  앱 시작 (app/app.dart를 띄운다)
  app/                       ← 지형주: 흐름 입구·조립·셸
    bootstrap.dart           실제/가짜 구현을 고르는 유일한 곳 (각자 자기 포트 줄만 수정)
    guide_flow.dart          현재 화면·상태, Gate(화면별 허용 행동), dispatch
    app.dart, home_screen.dart   화면 전환 셸, 홈(H)
  shared/
    contracts/               ← 공동: ActionId, ErrorCode, FlowState, ScreenId, 채널 요청·응답(analysis.dart)
    cells/                   ← 지형주: GuideScaffold(툴바·버튼), ScreenImage(원본 좌표 → 화면 좌표)
    theme/                   ← 지형주: Figma 색·글자·모서리·여백, Material 테마
  features/<기능>/
    domain/                  ← 공동: 포트(인터페이스)·모델
    data/                    ← 최정혁: 포트 구현 (analyze/data만 지형주, 강민준과 협의)
    ui/                      ← 지형주: 화면
    capture/       ImageInput · 갤러리(G·GS)·확인(GR) · 샘플 이미지·캐시 복사본
    analyze/       ScreenAnalyzer · MethodChannelAnalyzer(진짜)/FakeAnalyzer(가짜) · 분석 중(GA)
    guide/         결과(RG)·단계(D1~D5)·완료(DONE)·오류(E)
    guidance_map/  GuidanceRepository·MapUpdater · 체험용 기능 맵
    history/       HistoryRepository · 메모리 구현
    share/         Sharer · 가짜 구현
assets/samples/              체험용 샘플 이미지
contract_fixtures/analyze/   채널 요청·응답 예시 JSON (Flutter·Kotlin 공용 시험)
test/ports/                  포트 공용 시험(공동) — 진짜 구현도 같은 시험을 통과해야 bootstrap에서 교체
android/app/src/main/kotlin/com/screenguide/screen_guide/   ← 강민준
  logic/GuideLogic.kt        화면 식별·대상 찾기·개인정보 정규식 (Android 의존 없음)
  Analyzer.kt                ML Kit OCR·개체 추출
  MainActivity.kt            채널 screen_guide/analyze
```

폴더 구조와 소유는 Notion「화면길잡이_협업규격_최종」2장 기준이다. 의존 규칙: 기능 안에서 ui·data는 domain만 보고,
기능끼리는 서로의 domain과 shared/contracts만 본다. 구현 객체를 만드는 곳은 app/bootstrap.dart뿐이다.
예외 하나: 화면(ui)은 흐름 입구 `app/guide_flow.dart`를 본다 (`flow.dispatch`·`flow.allows`·상태 읽기).
화면이 data를 보지 않는다는 규칙은 그대로다. (11/11 결정 — 규격 2장 문장에 반영 요청)

규칙: 화면 위젯은 상태를 받아 그리기만 하고, 버튼은 `flow.dispatch(ActionId.xxx)`만 부른다.
업무 처리와 화면 전환은 `GuideFlow`가 한다.

## 남은 일

| 담당 | 할 일 |
|---|---|
| 팀원 1 강민준 (분석·AI) | Kotlin 채널을 계약 v1 형식으로 수정 (`imagePath`·`guidance`·`target` 받기, 응답 JSON, 요청으로 받은 맵 사용), OCR 글자 로그 제거, 정규식 `\b` 결함 수정. 지금 `FAKE_ANALYZER=false`로 돌리면 `NO_PATH`가 나는 것이 이 때문 |
| 팀원 2 지형주 (화면·흐름) | G·GS·RG 화면을 Figma 수치와 대조, ActionRegistry, P·SHARE·HISTORY·SETTINGS·DENY·카메라 화면 |
| 팀원 3 최정혁 (데이터·입출력) | 기능 맵 스키마·GuidanceRepository(체험용 `demo_guidance.dart` 교체), image_picker, 이력 DB, share_plus, Firebase |
| 공통 | release 빌드 시 ML Kit가 코드 축소(R8)로 깨져 시작 즉시 종료됨 → proguard keep 규칙 필요. 계약에 "선택 확정" ActionId 추가 여부 (지금은 `captureGallery` 재사용) |
