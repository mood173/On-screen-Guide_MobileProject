# 화면길잡이 (screen_guide)

팀원: 팀원 1 **강민준** (분석·AI) · 팀원 2 **지형주** (화면·흐름) · 팀원 3 **최정혁** (데이터·입출력)

화면 이미지 1장을 기기 안에서 분석해, 원하는 기능까지 누를 위치와 순서를 단계별로 안내하는 Android 앱.
**기준 문서: 최종 문서 5개** (저장소 `docs/공통_최종설계문/`, Notion「★최종 문서들」에도 있음) ← 작업 전에 먼저 읽기.
문서끼리 다르면 협업규격_최종이 기준이다.

| 문서 | 무엇의 기준인가 |
|---|---|
| [화면길잡이_협업규격_최종](../docs/공통_최종설계문/화면길잡이_협업규격_최종.md) | 폴더 소유, 공동 계약(포트·자료형·ActionId·맵·분석 규칙), 담당별 제공물, 협업 절차 |
| [화면길잡이_시스템설계_최종](../docs/공통_최종설계문/화면길잡이_시스템설계_최종.md) | 실행 단계 8개와 단계별 허용 버튼, 셸, 데이터 경계 |
| [화면길잡이_시스템역할설계](../docs/공통_최종설계문/화면길잡이_시스템역할설계.md) | 넘겨줄 기능 A·D·U 표와 일정, AI 작업 기록 양식 |
| [화면길잡이_기능별_검토_결론](../docs/공통_최종설계문/화면길잡이_기능별_검토_결론.md) | 위 결정의 근거, 제외·보류 기록(13장 X1~X9) |
| [화면길잡이_일정_현실검토](../docs/공통_최종설계문/화면길잡이_일정_현실검토.md) | 일정 조정안 (11/13 팀 확인 전) |

Figma「화면길잡이 · UI 설계서 v2 · Beta」대응표: [docs/figma.md](docs/figma.md).

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
flutter test                                        # Dart: 계약·예시 파일·포트 공용 시험·의존 규칙·흐름·화면 (69건)
cd android; .\gradlew.bat :app:testDebugUnitTest    # Kotlin: GuideLogicTest (28건)
```

`gradlew.bat`은 Git에 넣지 않는 파일이라, 처음 받은 뒤에는 `flutter run` 또는 `flutter build apk`를 한 번 해야 생긴다.

## 지금 되는 것

갤러리 흐름 전체가 Figma 화면대로 동작한다 (가짜 구현 + 샘플 이미지 2장). 흐름은 포트만 알고,
가짜/진짜는 `app/bootstrap.dart`에서 고른다.

```
H 홈 → G 최근 이미지 → GS 선택 → GR 선택한 이미지 → GA 분석 중 → RG 분석 결과
     → D1~Dn 단계별 안내 → DONE 안내 완료          (실패하면 E 다시 시도)
```

- 샘플: `demo.settings`(기능 2개, 1단계), `demo.chat`(기능 1개, 2단계, 개인정보 후보 5건)
- 가짜 분석기의 글자·위치는 샘플을 실제 ML Kit로 분석한 값이라 테두리가 이미지와 맞는다.
  화면 식별·대상 찾기 규칙(A·B·C)은 Kotlin 규칙의 복사본이다 (기준은 Kotlin)
- 사진은 앱 임시 폴더의 복사본으로 다루고, 홈으로 돌아가거나 다시 고르면 지운다. 앱 시작 때 남은 복사본도 지운다
- 카메라·실시간 스캔·기록·설정 버튼은 "준비 중" 안내만 띄운다. 결과(RG)에는 저장·공유가 없다 (X1)

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
    capture/       GalleryInput·CameraInput·InputCleanup · 갤러리(G·GS)·확인(GR) · 가짜 입력·샘플 이미지
    analyze/       ScreenAnalyzer · MethodChannelAnalyzer(진짜)/FakeAnalyzer(가짜)·샘플 정답 · 분석 중(GA)
    guide/         결과(RG)·단계(D1~D5)·완료(DONE)·오류(E)
    guidance_map/  GuidanceRepository·MapUpdater · 체험용 기능 맵
    history/       HistoryRepository · 메모리 구현
    share/         Sharer(ShareOutcome) · 가짜 구현
assets/samples/              체험용 샘플 이미지
contract_fixtures/analyze/   채널 요청·응답 예시 JSON (Flutter·Kotlin 공용 시험)
test/ports/                  포트 공용 시험(공동) — 진짜 구현도 같은 시험을 통과해야 bootstrap에서 교체
test/architecture/           폴더 의존 규칙 검사 (import)
test/support/test_flow.dart  시험용 흐름 조립 (가짜 구현 묶음)
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
버튼의 켜짐·꺼짐은 `flow.allows(id)`(단계별 허용 버튼)가 정한다. 화면이 따로 판단하지 않는다.
업무 처리와 화면 전환은 `GuideFlow`가 한다.

## 남은 일 (협업규격_최종 4장)

| 담당 | 할 일 |
|---|---|
| 강민준 (분석·AI) | Kotlin 채널을 계약 형식으로 (`requestId`·`imagePath`·`guidance`·`target`, 응답 JSON, 오류는 본문·대문자), 맵은 요청으로 받기(`SAMPLE_MAPS` 삭제), 로그에서 인식 글자·가린 값 제거, 분석 규칙 A·B·C, 개인정보 유형 9개, 정규식 `` 결함, 실제 앱 기능 맵 내용. **JUnit은 `contract_fixtures/analyze/`를 읽어 시험** — 화면 ID가 `demo.settings`·`demo.chat`, 앵커가 바뀌었다. 지금 `FAKE_ANALYZER=false`로 돌리면 `NO_PATH`가 난다 |
| 지형주 (화면·흐름) | 단계 설정표, 버튼 등록부와 핸들러, GuideSession, 카메라 화면(CP·CR·CA·RC)·권한 안내(DENY), 공유 전 확인(P)·공유(SHARE), 기록·설정 화면, 다른 화면 단계의 글 안내 카드·단계 맞추기, 복구 표, 진행 표시 5칸, 좌표 변환 함수 |
| 최정혁 (데이터·입출력) | **완료(PR #3)**: `CameraInput`(`PickerCameraInput`, image_picker)·`InputCleanup`(`FileInputCleanup`, app_settings) 진짜 구현, bootstrap 교체. **남은 것**: 기능 맵 스키마·실제 맵(체험용 `demo_guidance.dart` 교체), `GalleryInput` 진짜 구현, 기록 로컬 DB, Sharer, (선택) MapUpdater Firebase, CI. 진짜 구현은 `test/ports/`의 공용 시험을 통과한 뒤 bootstrap의 자기 줄만 바꾼다. 설계: `docs/cijghk/데이터_입출력_설계.md` |
| 공통 | release 빌드 시 ML Kit가 코드 축소(R8)로 깨져 시작 즉시 종료됨 → proguard keep 규칙 필요. 11/13 팀 확인: `ShareOutcome` 세 값, `packageName` 빈 문자열, 의존 규칙 예외(화면 → `app/guide_flow.dart`) |

일정 조정안(일정_현실검토)이 11/13에 채택되면 좌표 변환·공유 텍스트·단계 맞추기 함수, 복구 표, Flutter 쪽 분석기 파일은
강민준 담당으로 옮기고, 버튼 등록부 대신 빠짐없이 쓰는 switch로 한다.
