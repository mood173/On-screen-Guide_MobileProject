# 화면길잡이 · 사진 인식 앱 2107 MP3

MP1 이미지 입력과 MP2 온디바이스 한국어 OCR에 **결과 텍스트 이력, 개별 삭제, 시스템 공유 시트**를 추가한 Android Flutter 앱입니다.

## 실행

Android 기기/에뮬레이터 연결 후 이 폴더에서 `flutter pub get`, `flutter run`을 실행합니다. 카메라 촬영 또는 갤러리 선택 → 미리보기 → 이미지 표시 → 이미지 분석하기로 결과를 만듭니다. 결과는 자동으로 로컬 이력에 저장됩니다. 홈의 **분석 이력 보기**에서 목록·공유·삭제를 사용할 수 있습니다.

## 실제 구현

- Flutter `lib/main.dart` → `screen_guide/analyze` MethodChannel → Kotlin `Analyzer.analyzeOcr` → ML Kit Korean Text Recognition → 결과 화면.
- 분석 성공 콜백에서 Kotlin `HistoryStore`가 결과 텍스트·UUID·저장 시각만 Android `SharedPreferences`에 동기 저장합니다. `screen_guide/history` 채널로 목록·삭제·공유·임시 이미지 정리를 호출합니다.
- 인식 글자가 없으면 안내 텍스트를 저장합니다. 파일 읽기·OCR·저장 실패는 오류 안내로 구분합니다.
- 시스템 `ACTION_SEND`/`text/plain` 공유 시트에 결과 텍스트만 전달합니다.
- 개인정보와 임시 파일 범위는 `PRIVACY.md`를 참조하세요.

## 실제 실행 확인 (Android 에뮬레이터)

2026-11-10 `Resizable_Experimental` 에뮬레이터에서 이미지 선택→33줄 OCR→이력 저장→앱 강제 종료/재시작 후 이력 유지→시스템 공유 시트에서 텍스트 미리보기→개별 삭제 후 빈 목록까지 직접 확인했습니다. 앱 시작 후 `run-as`로 `cache/`를 조회해 이전 버전에서 남은 이미지 캐시 파일도 정리된 것을 확인했습니다. 비행기 모드 OCR과 빈 이미지 안내는 MP2에서 각각 확인했으며 같은 분석 경로를 MP3에서도 사용합니다. 증거 화면은 `screenshots/`에 있습니다. 실제 휴대전화의 카메라 품질은 별도 확인이 필요합니다.

## 제출

ZIP 최상위: `app/`, `README.md`, `screenshots/`, `prompts_log.md`, `PRIVACY.md`. 생성 폴더와 비밀 파일을 제외합니다.
