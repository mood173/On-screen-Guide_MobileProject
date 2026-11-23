# screen_guide — 수정 이력 (2026-11-23)

- 대상: `screen_guide/` (새 아키텍처 앱)
- 기준: `analysis` 브랜치 · HEAD `9d42278` + 이번 수정(미커밋)
- 함께 보는 문서: [screen_guide_오류수정_및_테스트가이드_2026-11-23.md](screen_guide_오류수정_및_테스트가이드_2026-11-23.md)
  (기능 목록·자동/수동 테스트 절차는 그 문서에 있다. 이 문서는 **"무엇을 어떻게 고쳤나"**만 기록한다.)

---

## 0. 요약

| 항목 | 값 |
|---|---|
| 수정 결함 | **14건** (E-1~E-14) |
| 팀 결정 대기 | 0건 — E-7은 `unknown` 신설로 종결 (11/23 결정 C안) |
| 수정 파일 | 기존 18개 (225 insertions / 100 deletions) |
| 신규 파일 | `lib/shared/coordinate_mapper.dart`, `lib/features/share/domain/share_draft.dart`, 루트 `.gitattributes`, Kotlin `UprightSizeTest.kt` |
| 추가 시험 | Dart **+3** (현재 선언 **226** — 포트 공용 시험의 헬퍼 중복 호출로 실행 건수는 더 많다), Kotlin **+5** (총 **72**) |
| 검증 수준 | 정적 검증 완료 · **컴파일/실행 미검증** (이 환경에 Flutter/Kotlin 툴체인 없음) |

> 원칙: **동작을 바꾸는 최소 변경**. 공개 계약(`ActionId`·`ScreenId`·채널 JSON·`HistoryEntry`)은 그대로 두고,
> 바뀐 공개 시그니처는 하나뿐이다 (→ §5 `GalleryInput.recent`).

---

## 1. 수정 목록

| ID | 결함 | 수정 내용 | 파일 |
|---|---|---|---|
| E-1 | EXIF 회전 미반영 | 응답 크기를 `uprightSize()`로 보정 + 시험 5건 | `Analyzer.kt`, `logic/GuideLogic.kt`, `UprightSizeTest.kt` |
| E-2 | 공유 예외 시 화면 갇힘 | `_shareSend`에 `catch` → 안내 + 들어온 곳 복귀 | `app/guide_flow.dart` |
| E-3 | 갤러리 실패 위장 | `GalleryPage{items, failed}` 도입, 실패 시 E 화면 | `capture/domain/image_input.dart`, `fake_input.dart`, `media_gallery_input.dart`, `guide_flow.dart` |
| E-4 | 흐름 계층 catch 0 | `dispatch`에 `try/catch/finally`, 분석 중 예외는 E | `app/guide_flow.dart` |
| E-5 | 취소 레이스 | `actionsFor` 뒤 `stage` 재확인 1줄 | `app/guide_flow.dart` |
| E-6 | 기록 중복 저장 | `_historySaved` 관문 + `_reset` 초기화 | `app/guide_flow.dart` |
| E-7 | 공유 결과 미확인 | `ShareOutcome.unknown` 신설 + 중립 안내("공유 시트를 열었어요") | `features/share/domain/sharer.dart`, `data/share_plus_sharer.dart`, `app/guide_flow.dart` |
| E-8 | 펼침 상태 미정리 | 재조회 실패 시 `openedEntry = null` | `app/guide_flow.dart` |
| E-9 | P 무반응 버튼 | draft null이면 문구 안내 후 유지 | `app/guide_flow.dart` |
| E-10 | DB close 호출자 0 | `AppDependencies.dispose()` + 앱 detach에서 호출 | `app/bootstrap.dart`, `main.dart` |
| E-11 | 화면 11개 홈 폴백 | 33개 화면 전수 case + `_NotBuilt` 안내 화면 | `app/app.dart` |
| E-12 | 좌표 변환 중복 | `shared/coordinate_mapper.dart`로 통합, `ScreenImage`가 사용 | `shared/coordinate_mapper.dart`(신규), `shared/cells/screen_image.dart` |
| E-13 | 흐름 파일에 UI 모델 | `ShareDraft`/`ShareCandidate` → 공유 도메인 | `features/share/domain/share_draft.dart`(신규), `guide_flow.dart`, `privacy_check_screen.dart` |
| E-14 | 줄바꿈 혼재 | `.gitattributes`(`* text=auto`) 추가 | 루트 `.gitattributes`(신규) |

---

## 2. 항목별 상세

### E-4 · 흐름의 예외 처리 (가장 큰 뿌리)

**문제**: `dispatch`가 `handle`을 그냥 `await`했다. 어떤 포트 구현이 예외를 던지면
`notifyListeners()`에 도달하지 못해 화면이 이전 상태에 멈추고, 사용자는 아무 안내도 받지 못한다.
(`guide_flow.dart`의 `try/finally` 8개, `catch` **0개**)

**수정 전**
```dart
Future<void> dispatch(ActionId id, [Object? arg]) async {
  if (!allows(id)) return;
  await handle(id, arg);
  notifyListeners();
}
```

**수정 후**
```dart
Future<void> dispatch(ActionId id, [Object? arg]) async {
  if (!allows(id)) return;
  try {
    await handle(id, arg);
  } catch (e, st) {
    debugPrint('[flow] $id 실패: $e\n$st');
    _pendingId = null;  _slowTimer?.cancel();  slow = false;
    locating = false;   _capturing = false;
    _loadingRecords = false;  _sharing = false;
    notice = '문제가 생겼어요. 다시 시도해 주세요';
    if (screen.stage == Stage.analyze) _fail(ErrorCode.analysisFailed);
  } finally {
    notifyListeners();
  }
}
```

**설계 판단**
- `notifyListeners()`를 `finally`로 옮긴 것이 핵심 — 예외로 끝나도 바뀐 상태를 그린다.
- 잠금 플래그를 전부 푼다(잠금이 남으면 모든 버튼이 영구 비활성이 된다).
- **분석 단계에서만** E 화면으로 보낸다. 기록·설정에서 난 예외까지 E로 보내면
  사용자가 보던 화면을 빼앗기 때문(그 경우는 스낵바만).

---

### E-2 · 공유 실패

**문제**: `_shareSend`는 `try/finally`만 있어, `_sharer.shareText`가 던지면 잠금만 풀리고
`notice`도 `_leaveShare()`도 실행되지 않는다 → **SHARE 화면에 갇힘**.

**수정**: `catch` 추가(안내 후 `_leaveShare`). 공유 결과 3분기(`sent`/`dismissed`/`failed`) 로직은 그대로.

```dart
} catch (e) {
  debugPrint('[share] 실패: $e');
  notice = '공유하지 못했어요. 다시 시도해 주세요';
  await _leaveShare();
} finally {
  _sharing = false;
}
```

---

### E-5 · 취소 레이스

**문제**: `_analyze()` 성공 후 `await _guidance.actionsFor(...)` 동안 사용자가 취소하면
`_cancel()`이 GR로 보내지만, await 복귀 후 `_go(RG)`가 **취소를 덮어썼다**.
(`_pendingId`는 성공 시점에 이미 `null`이라 되돌릴 표식이 없었다.)

**수정(1줄)**
```dart
availableActions = await _guidance.actionsFor(r.screenId!);
if (screen.stage != Stage.analyze) return; // 취소·뒤로가기로 이미 떠났다
_go(...);
```

**주의**: `AssetGuidanceRepository.actionsFor`는 캐시된 Future라 실제 탭이 끼어들 확률은 낮다.
DB/네트워크 구현으로 바뀌면 즉시 재현되는 **잠재 결함**이었다.

---

### E-6 · 기록 중복 저장

**문제**: `_saveHistory`의 id가 `h{microseconds}`라 누를 때마다 새 행. DONE에서 버튼도 계속 열려 있었다.

**수정**: 세션 단위 1회. 저장 성공 시 `_historySaved = true`,
`allowed`에서 `historySave`를 제거(→ 화면 버튼이 자동 비활성), `_reset`에서 초기화.

```dart
if (_historySaved) s.remove(ActionId.historySave);
```

> DONE에서 뒤로 갔다가 다시 와도 같은 안내 세션이면 저장 버튼은 잠긴다(의도).

---

### E-3 · 갤러리 실패 구분 (공개 시그니처 1건 변경)

**문제**: `recent()`가 실패를 `[]`로 돌려줘 "사진이 0장"과 "읽지 못함"이 같은 값이었다.

**수정**: `GalleryPage{items, failed}` 도입.
```dart
// domain/image_input.dart
class GalleryPage {
  const GalleryPage({required this.items, required this.failed});
  final List<GalleryItem> items;
  final bool failed;   // 읽기 자체가 실패 — 권한 거부는 requestAccess가 판단
}
Future<GalleryPage> recent({int limit = 9});
```
```dart
// guide_flow.dart _openGallery
final page = await _gallery.recent();
if (page.failed) return _fail(ErrorCode.imageReadFailed);
galleryItems = page.items;
```

**⚠️ 팀 공유 필요**: `GalleryInput`을 구현한 곳은 `FakeGalleryInput`·`MediaGalleryInput` 두 곳뿐이라
둘 다 수정했고, 시험 3파일도 맞췄다. **다른 사람이 별도 구현을 갖고 있다면 반환형을 바꿔야 한다.**

---

### E-8 · 펼침 상태 / E-9 · P 무반응 버튼

```dart
// E-8
if (e == null) { openedEntry = null; historyItems = await _history.list(); return; }
// E-9
if (shareDraft == null) { notice = '공유할 내용이 없어요'; return; }
```
E-9는 화면을 옮기지 않는다 — draft가 없는데 `_leaveShare()`를 부르면 DONE으로 갔다가
`action`이 null인 화면을 그릴 위험이 있어, **문구만 남기는 쪽**을 택했다.

---

### E-7 · 공유 결과 미확인 (`unavailable`) — 11/23 결정 C안

**문제**: `share_plus`는 플랫폼이 결과를 알려주지 못할 때 `unavailable`을 준다.
이 값을 `sent`로 매핑하면, 사용자가 시트를 닫아도 **"공유했어요"** 가 떠서
하지 않은 일을 했다고 말하게 된다 (개인정보/공유 화면에서 특히 나쁘다).

**수정**
```dart
// domain/sharer.dart — 값 하나 추가
enum ShareOutcome { sent, dismissed, unknown, failed }

// data/share_plus_sharer.dart — 매핑
ShareResultStatus.unavailable => ShareOutcome.unknown,

// app/guide_flow.dart _shareSend — 안내 구역 추가
case ShareOutcome.unknown:
  notice = '공유 시트를 열었어요';   // 성공 단정 없이 사실만
```

**왜 B(`→ dismissed`)가 아니라 C인가**
- B는 실제로 공유한 사용자에게도 피드백이 없어 **재시도(중복 전송)** 를 유도한다.
- 이 앱은 이미 "모르면 모른다고 말한다"는 원칙을 갖고 있다 (E 화면의 "추정해서 안내하지 않아요").
- `ShareOutcome`을 늘리면 `switch`가 전수라 **문구 누락이 컴파일 오류로 잡힌다**.

**검증**: `share_plus_sharer_test`(`unavailable → unknown`) · `guide_flow_test`(미확인 안내 1건).
실기기에서 `unavailable`이 실제로 오는 비율은 로그 1줄로 확인 권장:
`debugPrint('[share] status=${r.status}')`.

---

### E-10 · DB 수명주기

```dart
// AppDependencies
Future<void> dispose() async {
  final h = history;
  if (h is SqliteHistoryRepository) await h.close();
}
```
```dart
// main.dart
final deps = bootstrap();
final flow = deps.createFlow()..start();
runApp(ScreenGuideApp(flow: flow));
AppLifecycleListener(onDetach: () => unawaited(deps.dispose()));
```
> Android에서 프로세스가 강제 종료되면 `onDetach`가 오지 않는다 — 그때는 OS가 회수한다.
> 이 수정의 목적은 "닫는 코드가 아예 없는 상태"를 없애는 것이다.

---

### E-11 · 화면 라우팅 전수화

`_screen()`의 `_ => HomeScreen` 폴백을 제거하고 **33개 ScreenId를 전부 명시**했다.
`ScreenId.c`(기기 카메라가 대신)와 오버레이 10개는 `_NotBuilt` 안내 화면으로 보낸다.
→ 화면이 늘어나면 **컴파일 오류**로 빠뜨림이 드러난다(단계표와 같은 원칙).

검증: enum 값 33개 ↔ case 33개 일치(스크립트 대조), default 없음.

---

### E-12 · 좌표 변환 통합

`shared/coordinate_mapper.dart`의 `mapBox(box, image:, view:)`로 한 벌만 두고
`ScreenImage`가 그것을 쓴다(계산식 동일 — `view.width/image.width` 비율 곱).

```dart
final imageSize = Size(w.toDouble(), h.toDouble());
Rect map(Box b) => mapBox(b, image: imageSize, view: c.biggest);
```

**같은 파일 부수 수정 — 원본 크기 0 처리**

`imageWidth`/`imageHeight`가 `0`일 때 `AspectRatio(aspectRatio: 0)`은 `aspectRatio > 0` assert에 걸린다.
`test/shared/cells/screen_image_test.dart`의 "원본 크기가 0이면 깨지지 않고 사진만 그린다"가 이 경로를 검사하고 있어,
`null`과 `0`을 **같은 경로**(사진만 그리기)로 처리하도록 고쳤다.

```dart
final sized = w != null && h != null && w > 0 && h > 0;
final image = Image.file(..., fit: sized ? BoxFit.fill : BoxFit.contain, ...);
if (w == null || h == null || w <= 0 || h <= 0) { return /* 사진만 */; }
```

**복구 경위**: `test/shared/coordinate_mapper_test.dart`(7건)와 `screen_image_test.dart`(2건)는
`origin/feat/coordinate-mapper`에서 온 시험인데, 이 브랜치에는 `lib/shared/coordinate_mapper.dart`가
없어 **컴파일조차 되지 않던 상태**였다. 이번에 lib 파일을 추가하고 크기 0 처리를 맞춰 두 시험이 성립한다.

---

### E-13 · 모델 위치 정상화

`ShareDraft`·`ShareCandidate`를 `features/share/domain/share_draft.dart`로 이동.
- `privacy_check_screen.dart`는 이제 `app/guide_flow.dart`가 아니라 **공유 도메인**을 본다 (레이어 정상).
- 기존 `ui → app/guide_flow` 예외는 "화면이 흐름을 부를 때"만 남는다.

---

### E-14 · 줄바꿈

루트에 `.gitattributes`(`* text=auto` + 이미지/바이너리 예외)를 추가했다.

**즉시 효과(실측)**: `git diff --stat`이 234파일 → **14파일**로 줄었다.
CRLF/LF 차이는 이제 diff에 나타나지 않고, 실제 내용 변경만 보인다.

**팀이 한 번 할 일**
```bash
git add --renormalize .
git commit -m "chore: 줄바꿈 정규화 (.gitattributes)"
```
> 이 커밋을 하지 않아도 diff는 정상으로 보인다. 다만 저장소에 저장되는 줄바꿈은
> 다음 커밋 때 LF로 정규화된다.

---

## 3. 추가/변경된 시험

| 파일 | 변경 | 고정하는 것 |
|---|---|---|
| `android/.../UprightSizeTest.kt` | 신규 5건 | 0/180/90/270도 + 음수·360 초과 정규화 (EXIF) |
| `test/app/guide_flow_test.dart` | +3건 | E-6 중복 저장 차단 / E-4 예외 시 복구(E 화면·문구) / E-7 결과 미확인 안내 |
| `test/features/share/data/share_plus_sharer_test.dart` | 수정 1건 | `unavailable → unknown` (성공 단정 금지) |
| `test/features/capture/data/media_gallery_input_test.dart` | 수정 | `GalleryPage.items`·`failed` 구분 (읽기 실패 = failed) |
| `test/ports/port_contracts.dart`, `fakes_contract_test.dart` | 수정 | 새 반환형에 맞춘 계약 검사 |
| `test/features/privacy/privacy_check_screen_test.dart` | import 1줄 | 모델 이동 |

---

## 4. 검증 결과 (실출력)

```
$ git diff --ignore-cr-at-eol --stat -- screen_guide
 18 files changed, 225 insertions(+), 100 deletions(-)

$ python3 (괄호 균형 검사, 주석·문자열 제거 후)
 lib/app/guide_flow.dart    {} 92/92   () 243/243   [] 18/18   OK
 lib/app/app.dart           {} ...    OK
 lib/app/bootstrap.dart     OK
 lib/main.dart              OK
 lib/features/capture/domain/image_input.dart         OK
 lib/features/capture/data/fake_input.dart            OK
 lib/features/capture/data/media_gallery_input.dart   OK
 lib/features/privacy/ui/privacy_check_screen.dart    OK
 lib/features/share/domain/share_draft.dart           OK
 lib/shared/coordinate_mapper.dart                    OK
 lib/shared/cells/screen_image.dart                   OK
 test/.../port_contracts.dart, fakes_contract_test.dart, media_gallery_input_test.dart, privacy_check_screen_test.dart  OK

$ ScreenId 라우팅 대조
 enum 33 / case 33 / missing none / unknown none / default 없음

$ 테스트 개수
 Dart test( · testWidgets( 선언: 226 (실행 건수는 포트 공용 시험 헬퍼 호출로 더 많음)
 Kotlin @Test: 72 (GuideLogic 28 + Rules 32 + ChannelCodec 7 + UprightSize 5)
```

**미실행(개발 PC에서 확인 필요)**: `flutter analyze` / `flutter test` / `:app:testDebugUnitTest` / 실기기 EXIF 좌표.

---

## 5. 주의 — 팀에 공유할 변경

1. **`GalleryInput.recent()` 반환형 변경**: `Future<List<GalleryItem>>` → `Future<GalleryPage>`.
   구현을 새로 만들었다면 `.items`를 돌려주도록 고쳐야 한다.
2. **`AppDependencies.dispose()` 추가**: 앱 종료 시 호출(테스트에서도 정리용으로 사용 가능).
3. **`ShareDraft`/`ShareCandidate` import 경로 변경**:
   `app/guide_flow.dart` → `features/share/domain/share_draft.dart`.
4. **`.gitattributes` 추가**: 다음 커밋에서 줄바꿈이 정규화된다.
5. **`ShareOutcome`에 `unknown` 추가** (4값): 공유 결과를 `sent/dismissed/unknown/failed`로 다룬다.
   `switch`가 전수라 빠뜨리면 컴파일 오류가 난다. `unknown`은 "결과 미확인"이며 성공이 아니다.

---

## 6. 롤백

```bash
# 이번 수정 전체 취소 (미커밋 상태 기준)
git checkout -- screen_guide/lib screen_guide/test screen_guide/android
git clean -f screen_guide/lib/shared/coordinate_mapper.dart \
               screen_guide/lib/features/share/domain/share_draft.dart \
               screen_guide/android/app/src/test/kotlin/com/screenguide/screen_guide/UprightSizeTest.kt
# .gitattributes만 남기고 싶으면 그대로 두고, 아니면 삭제
```
> `git clean`은 새 파일만 지운다. 팀 파일은 건드리지 않는다.

---

## 7. 남은 것

| 항목 | 상태 | 비고 |
|---|---|---|
| `GuideFlow` 885줄 분리 | ⬜ | 동작과 무관한 구조 작업 |
| `git add --renormalize` 커밋 | ⬜ | 팀 1회 |
| 실기기 EXIF 검증 | ⬜ | 가이드 §5 T5 |
| `flutter analyze`/`test` 출력 | ⬜ | 가이드 §4 |
