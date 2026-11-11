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

### 팀 확인 필요

1. **하단 진행 표시**: 설계 3장은 "모든 화면 하단에 입력 → 분석 → 기능 선택 → 안내 → 완료" 진행 표시를 두는데,
   Figma v2에는 없다. 홈은 하단 탭(홈·기록·설정), 단계 화면은 위쪽 진행 막대만 있다.
2. **P 화면 개인정보 예시**: "이름 · 연락처 · 배달 주소"로 되어 있으나, 중간 보고서 기준(12.1 ②) 이름은 검출 대상이 아니다.
3. **D1~D5 복사본**: 같은 내용의 프레임이 4벌(이름 끝 1/5·1/6·1/7·1/8) 겹쳐 있다. 코드는 처음 만든 `15:` 계열을 기준으로 한다.
   필요 없는 복사본은 Figma에서 정리하면 혼동이 줄어든다.
