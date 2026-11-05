// 디자인 값. 출처: Figma「화면길잡이 · UI 설계서 v2 · Beta」(2026-11-06 추출)
//
// Figma 파일에는 색·글꼴 스타일이나 변수가 정의되어 있지 않아, 프레임에 직접 쓰인 값을
// 역할별로 모아 이름을 붙였다. Figma 프레임 폭 412px = Flutter 논리 픽셀 412로 1:1 대응한다.
// 값을 바꿀 때는 Figma를 먼저 고치고 여기를 맞춘다.

import 'package:flutter/painting.dart';

abstract final class AppColors {
  // 바탕·면
  static const background = Color(0xFFF7F9FC); // 모든 화면 배경
  static const surface = Color(0xFFFFFFFF); // 카드·하단 탭
  static const divider = Color(0xFFE4E6F0); // 진행 막대 빈 칸, 구분선

  // 글자
  static const textPrimary = Color(0xFF182338); // 제목·본문
  static const textStatus = Color(0xFF171F33); // 상태 표시줄·툴바
  static const textSecondary = Color(0xFF7B8497); // 보조 설명, 비활성 탭
  static const textTertiary = Color(0xFF49536A); // 보조 버튼 글자
  static const chevron = Color(0xFFA4ACBA); // 목록 오른쪽 ›

  // 주 색 (인디고)
  static const primary = Color(0xFF5653E8); // 주 버튼, 활성 탭, 진행 막대, 목표 UI 테두리
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryDeep = Color(0xFF36349B); // 단계 안내 카드 제목
  static const primarySoft = Color(0xFFEFEEFF); // 단계 안내 카드 배경
  static const instructionSub = Color(0xFF6B6C86); // 단계 안내 카드 보조 문구
  static const secondaryButton = Color(0xFFEEF0F7); // 보조 버튼 배경 ("화면이 달라요" 등)

  // 홈 상단 안내 카드 (온디바이스 고지)
  static const hero = Color(0xFF1E2443);
  static const heroSub = Color(0xFFC3C8DF);
  static const heroAccent = Color(0xFFA9B5FF);

  // 입력 방식 아이콘 타일
  static const tileCamera = Color(0xFFF0EEFF);
  static const tileGallery = Color(0xFFE8F5F0);
  static const tileGalleryIcon = Color(0xFF27896A);
  static const tileLive = Color(0xFFFFF1E4);
  static const tileLiveIcon = Color(0xFFC8752A);

  // 강조 의미 (설계 6.2 Emphasis: active / done / privacy)
  static const emphasisActive = Color(0xFFF4BD68); // 주황: 안내 활성
  static const emphasisDone = Color(0xFF53A779); // 초록: 완료·보호 상태
  static const target = primary; // 목표 UI 테두리

  // 주의·개인정보 (P, E 화면)
  static const caution = Color(0xFFC8752A); // 경고 아이콘
  static const privacySurface = Color(0xFFFFF3E6); // 개인정보 후보 카드 배경
  static const privacyTitle = Color(0xFF8F541F);
  static const privacyBody = Color(0xFF7E6853);
}

abstract final class AppRadius {
  static const button = 16.0; // 주·보조 버튼
  static const card = 22.0; // 카드, 입력 방식 목록, 하단 탭, 안내 카드
  static const tile = 14.0; // 아이콘 타일
}

abstract final class AppSpace {
  static const screenH = 24.0; // 화면 좌우 여백
  static const screenTop = 16.0;
  static const section = 16.0; // 본문 블록 사이
  static const cardPad = 14.0; // 목록 카드 안쪽
  static const cardPadLarge = 20.0; // 홈 상단 카드 안쪽
  static const instructionPad = 16.0;
  static const buttonHeight = 52.0;
  static const progressHeight = 5.0;
  static const targetStroke = 3.0; // 목표 UI 테두리 두께
}

/// 글자 크기·굵기. Figma 글꼴은 Noto Sans KR이고, Android 기본 한글 글꼴(Noto Sans CJK)과 같은 계열이라
/// 글꼴 파일을 따로 넣지 않는다. (오프라인 동작 요구 때문에 google_fonts 패키지는 쓰지 않는다)
abstract final class AppText {
  static const _w4 = FontWeight.w400,
      _w5 = FontWeight.w500,
      _w7 = FontWeight.w700;

  static const headline = TextStyle(
    fontSize: 27,
    fontWeight: _w7,
    color: AppColors.textPrimary,
    height: 1.4,
  ); // 홈 큰 제목
  static const title = TextStyle(
    fontSize: 20,
    fontWeight: _w7,
    color: AppColors.textPrimary,
  );
  static const section = TextStyle(
    fontSize: 16,
    fontWeight: _w7,
    color: AppColors.textPrimary,
  ); // "어떤 방법으로 시작할까요?"
  static const toolbar = TextStyle(
    fontSize: 16,
    fontWeight: _w5,
    color: AppColors.textStatus,
  );
  static const listTitle = TextStyle(
    fontSize: 15,
    fontWeight: _w7,
    color: AppColors.textPrimary,
  );
  static const button = TextStyle(fontSize: 15, fontWeight: _w5);
  static const instructionTitle = TextStyle(
    fontSize: 17,
    fontWeight: _w7,
    color: AppColors.primaryDeep,
  );
  static const body = TextStyle(
    fontSize: 13,
    fontWeight: _w4,
    color: AppColors.textSecondary,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: _w4,
    color: AppColors.textSecondary,
  );
  static const tab = TextStyle(fontSize: 14, fontWeight: _w5);
}
