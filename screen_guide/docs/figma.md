# Figma UI 설계 연결

- 파일: [화면길잡이 · UI 설계서 v2 · Beta](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=14-113)
  (페이지 `02 · Beta 2 — 세 가지 입력 흐름`, 열람에 Figma 로그인 필요)
- 추출일: 2026-11-06
- 코드 연결
  - 화면 ID ↔ 프레임: `lib/shared/contracts/screen_id.dart` (`ScreenId.figmaNode`, `ScreenId.figmaUrl`)
  - 색·글자·모서리·여백: `lib/shared/theme/app_tokens.dart`
  - Material 테마: `lib/shared/theme/app_theme.dart` (`AppTheme.light()`)

## 화면 ID ↔ Figma 프레임

프레임 크기는 모두 412×892 (Flutter 논리 픽셀과 1:1).

| 흐름 | 화면 ID | Figma 프레임 | node-id |
|---|---|---|---|
| 홈 | H | 홈 | [14:114](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=14-114) |
| 카메라 | CP | 카메라 접근 | [15:113](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-113) |
| | C | 카메라 촬영 | [15:119](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-119) |
| | CR | 촬영한 사진 | [15:125](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-125) |
| | CA | 사진 분석 중 | [15:131](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-131) |
| | RC | 카메라 분석 결과 | [15:137](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-137) |
| 갤러리 | G | 최근 이미지 | [15:143](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-143) |
| | GS | 이미지 선택 | [15:149](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-149) |
| | GR | 선택한 이미지 | [15:155](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-155) |
| | GA | 이미지 분석 중 | [15:161](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-161) |
| | RG | 갤러리 분석 결과 | [15:167](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-167) |
| 단계 안내 | D1 | 단계별 안내 · 1 / 5 | [15:233](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-233) |
| | D2 | 단계별 안내 · 2 / 5 | [15:239](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-239) |
| | D3 | 단계별 안내 · 3 / 5 | [15:245](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-245) |
| | D4 | 단계별 안내 · 4 / 5 | [15:251](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-251) |
| | D5 | 단계별 안내 · 5 / 5 | [15:257](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-257) |
| | DONE | 안내 완료 | [15:293](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-293) |
| 실시간 (N01) | LP | 실시간 안내 설정 | [15:173](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-173) |
| | L | 실시간 인식 (닫힘) | [15:179](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-179) |
| | LO | 실시간 인식 (열림) | [15:185](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-185) |
| | LT | 원하는 기능 | [15:191](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-191) |
| | LX | 현재 화면 스캔 | [15:197](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-197) |
| | LG1~LG5 | 실시간 안내 · 1~5 / 5 | [15:203](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-203) · [15:209](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-209) · [15:215](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-215) · [15:221](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-221) · [15:227](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-227) |
| 공유·기록·설정 | P | 공유 전 확인 | [15:263](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-263) |
| | SHARE | 공유하기 | [15:299](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-299) |
| | HISTORY | 내 안내 기록 | [15:269](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-269) |
| | SETTINGS | 설정 | [15:275](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-275) |
| 복구 | DENY | 권한이 필요해요 | [15:287](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-287) |
| | E | 다시 시도 | [15:281](https://www.figma.com/design/QqKYcVCHek9vY3pOLKf6cF/?node-id=15-281) |

설계 문서(기능·개념 정리 7장)의 화면 ID는 모두 프레임이 있다.

## 디자인 값 요약

Figma에 색·글자 스타일과 변수가 정의되어 있지 않아, 프레임에 직접 쓰인 값을 역할별로 묶었다.

| 역할 | 값 |
|---|---|
| 배경 / 카드 | `#F7F9FC` / `#FFFFFF` |
| 글자 (주·보조·보조 버튼) | `#182338` / `#7B8497` / `#49536A` |
| 주 색 (주 버튼·활성 탭·진행 막대·목표 UI 테두리) | `#5653E8` |
| 단계 안내 카드 (배경·제목·보조) | `#EFEEFF` / `#36349B` / `#6B6C86` |
| 보조 버튼 배경 | `#EEF0F7` |
| 강조: 활성(주황) / 완료(초록) | `#F4BD68` / `#53A779` |
| 주의·개인정보 (아이콘·카드·제목) | `#C8752A` / `#FFF3E6` / `#8F541F` |
| 글꼴 | Noto Sans KR (Regular·Medium·Bold) — Android 기본 한글 글꼴과 같은 계열이라 따로 넣지 않음 |
| 모서리 | 버튼 16 · 카드 22 · 아이콘 타일 14 |
| 여백 | 화면 좌우 24 · 블록 사이 16 · 버튼 높이 52 · 목표 테두리 3 |

## 설계 문서와 다른 점

### 정리됨 (2026-11-06)

- **글자 크기**: Figma 값 그대로 쓴다. (NFR-03 "안내 글자 16pt 이상"과 다른 12~15 글자도 바꾸지 않음)
- **예시 앱**: Figma의 치킨 주문 화면은 흐름을 보여 주는 예시일 뿐이다. 앱 화면을 찍거나 이미지를 올려 단계 안내를 받는
  흐름은 대상 앱이 무엇이든 같다. 화면 구성은 Figma를 따르고, 문구·이미지는 실제 기능 맵 내용으로 채운다.

### 확정·확인 필요

1. **하단 진행 표시**: 넣기로 확정 (시스템설계_최종 10장 ①). UI 설계서(PDF)에는 있고 Figma v2에서 빠졌으므로
   Figma에 다시 넣는다. 홈은 하단 탭(홈·기록·설정), 안내 셸 화면에 진행 표시 5칸.
2. **P 화면 개인정보 예시**: "이름 · 연락처 · 배달 주소"로 되어 있으나, 중간 보고서 기준(12.1 ②) 이름은 검출 대상이 아니다.
3. **D1~D5 복사본**: 같은 내용의 프레임이 4벌(이름 끝 1/5·1/6·1/7·1/8) 겹쳐 있다. 코드는 처음 만든 `15:` 계열을 기준으로 한다.
   필요 없는 복사본은 Figma에서 정리하면 혼동이 줄어든다.
4. **HISTORY (15:269)** — 2026-11-22 정함: 기능은 문서, 모양은 Figma.
   - Figma는 툴바(‹) + 하단 버튼 "새 화면 안내받기", 하단 탭 없음 → **앱 셸 하단 탭**(시스템설계 4-1, 3-9). "새 화면 안내받기"는
     기록 단계 허용 버튼(3-9)에 맞는 것이 없어 뺀다 (홈 탭이 같은 일).
   - Figma에 지우기가 없음 → **줄마다 지우기 + 한 번 확인**(3-9 규칙, 9장, MP3 "이력 삭제").
   - 기록 줄: Figma "입력 방식 · 기능 이름", 문서(4-2) "제목, 시각" → **둘 다**: 기능 제목 / 입력 방식 · 시각.
   - 그대로 쓰는 것: 제목 "내가 찾은 사용법", 부제, "최근 안내 · N개"(데모 개수 대신 실제 개수), 원본 미저장 안내 상자, 글자·색.
5. **SETTINGS (15:275)** — 2026-11-22 정함: 기능은 문서, 모양은 Figma.
   - 툴바(‹)·하단 "홈으로 돌아가기" → **앱 셸 하단 탭** (HISTORY와 같음).
   - 회색 줄 3개 → **2개**: "실시간 인식 · 권한 관리" → **"카메라·사진 권한 관리"**(기기 설정 열기, N01은 일정 제외),
     "저장한 안내 기록"은 그대로(기록 화면), "개인정보와 공유 안내"는 뺌(맞는 버튼 ID·화면 없음).
   - "이번 베타에서 체험할 수 있어요" 카드 → 같은 모양에 **"안내 자료 버전"(기능 맵 revision, 문서 3-9·D7)** +
     "안내 자료는 기기 안에 있어서 인터넷 없이도 안내해요." (원래 글 "실제 촬영·AI 분석… 실행하지 않아요"는 지금 사실이 아님).
     맵을 못 읽으면 "확인할 수 없어요".
   - 권한 상태 글자·동기화 동의는 그리지 않음 (상태만 읽는 포트 없음 / 시스템설계 8장 "되면 넣는다").
   - 그대로 쓰는 것: 제목 "편리하게, 안심하고", 부제 "화면길잡이 · BETA 2"(최종 제출 전 8번 점검 때 다시 봄), 줄 버튼·카드 모양, 글자·색.
6. **P (15:263)** — 2026-11-22 정함: 기능은 문서, 모양은 Figma.
   - 부제 "사진과 결과에 개인정보가 포함될 수 있어요." → 검토 결론 5장 문장 **"이 화면에는 개인정보 후보 N건이 있었어요. 보내는 것은 사용 방법 글뿐이에요."**
     (0건: "개인정보 후보는 찾지 못했어요. …"). 보내는 것은 사용 방법 글뿐이라 "사진"은 틀린 말.
   - 카드 "개인정보 후보 · 예시 / 이름 · 연락처 · 배달 주소" → 같은 주황 카드에 **실제 목록**("개인정보 후보 N건", 줄마다 유형 + 가린 값, 기록에서 왔으면 유형만).
     "검사는 주의를 돕는 기능이며, 개인정보가 없음을 보증하지 않아요."는 **남김** (제약 C06).
   - 보조 버튼 "안내 기록에 저장" 뺌 (3-8: P에는 확인·뒤로만). 작은 글 "체험 화면 · 실제 외부 앱으로 전송하지 않아요" 뺌 (5-5부터 실제 공유).
   - 주 버튼 "내용 확인 후 결과만 공유" → **"확인했어요 · 사용 방법만 공유"** ("결과"가 사진·글자로 들리지 않게).
   - 그대로 쓰는 것: 툴바 "‹ 공유 전 확인", 방패 아이콘, 제목 "공유하기 전에 / 한 번 더 확인해요", 주황 카드 색·모양, 주 버튼 모양.
7. **DONE (15:293)** — 2026-11-22: Figma에 공유 버튼이 없음 → 3-7 마무리 허용 버튼 `sharePrepare`대로 **"공유하기" 보조 버튼**을
   "안내 기록에 저장"과 "새로운 화면 안내받기" 사이에 더함. 기록 화면은 펼친 카드 안에 "이 안내 공유하기".
8. **SHARE (15:299)** — 2026-11-22 정함: 기능은 문서, 모양은 Figma.
   - 주황 카드 "치킨 주문하기 · 사용 방법 / 1 … 5" → **실제로 보낼 글을 그대로** (`buildShareText` 결과. 첫 줄은 굵게, 글자는 안 바꿈).
   - 주 버튼 "공유 완료 · 체험" → **"보내기"**(`shareSend`, 실제 공유 시트). 작은 글 "체험 화면 · 실제 외부 앱으로 전송하지 않아요" 뺌.
   - 그대로 쓰는 것: 툴바 "‹ 공유하기", 아이콘 자리, 제목 "공유할 내용을 / 확인해 주세요", 부제 "원본 이미지 없이 사용 방법만 공유합니다."(사실과 맞음),
     보조 버튼 "돌아가기"(`navBack` → P), 카드 색·모양.
