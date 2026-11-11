// 체험용 샘플 이미지의 "정답" 분석 결과. 가짜 분석기(FakeAnalyzer)만 쓴다.
// 이미지 목록(어떤 샘플이 있는지)은 capture/data/sample_images.dart에 있고, 둘은 파일 이름으로 이어진다.
//
// OCR 결과는 시험 앱(screen_guide_test)의 실제 ML Kit 출력(에뮬레이터, 2026-11-06)을 옮긴 것이라
// 상자 위치가 이미지와 정확히 맞는다. 체험 화면에 보이는 글자라 명백한 오인식 3곳은 고쳤다
// (핫스핏→핫스팟, glldong→gildong, 겹쳐 읽힌 "본요" 줄 제거).

import 'package:screen_guide/shared/contracts/analysis.dart';

class SampleAnswer {
  const SampleAnswer({
    required this.fileName,
    required this.width,
    required this.height,
    required this.screenId,
    required this.elements,
    this.pii = const [],
  });

  /// 샘플 이미지의 파일 이름. 분석 요청 imagePath의 마지막 부분과 비교한다.
  final String fileName;
  final int width, height;
  final String? screenId;
  final List<UiElement> elements;
  final List<PiiCandidate> pii;

  /// 에셋 경로 또는 캐시에 복사한 파일 경로로 정답을 찾는다 (파일 이름으로 비교).
  static SampleAnswer? byPath(String path) {
    final name = path.split(RegExp(r'[\\/]')).last;
    for (final s in all) {
      if (s.fileName == name) return s;
    }
    return null;
  }

  static const settings = SampleAnswer(
    fileName: 'sample_settings.png',
    width: 1080,
    height: 2340,
    screenId: 'demo.settings',
    elements: [
      UiElement(label: '10:23', box: Box(45, 23, 120, 50)),
      UiElement(label: 'LTE 87%', box: Box(914, 25, 1037, 50)),
      UiElement(label: '설정', box: Box(52, 153, 165, 218)),
      UiElement(label: '설정 검색', box: Box(69, 293, 233, 337)),
      UiElement(label: '네트워크 및 인터넷', box: Box(175, 457, 519, 498)),
      UiElement(label: '모바일, Wi-Fi, 핫스팟', box: Box(173, 523, 462, 557)),
      UiElement(label: '연결된 기기', box: Box(155, 642, 381, 690)),
      UiElement(label: '블루투스, 페어링', box: Box(173, 715, 396, 748)),
      UiElement(label: '앱', box: Box(174, 838, 208, 878)),
      UiElement(label: '최근 앱, 기본 앱', box: Box(173, 906, 381, 939)),
      UiElement(label: '알림 설정', box: Box(174, 1029, 341, 1070)),
      UiElement(label: '알림 기록, 대화', box: Box(173, 1097, 376, 1130)),
      UiElement(label: '배터리', box: Box(175, 1220, 290, 1261)),
      UiElement(label: '85% · 약 1일 남음', box: Box(173, 1288, 424, 1318)),
      UiElement(label: '저장용량', box: Box(173, 1411, 335, 1452)),
      UiElement(label: '52% 사용 중', box: Box(172, 1478, 342, 1509)),
      UiElement(label: '소리 및 진동', box: Box(173, 1602, 396, 1643)),
      UiElement(label: '볼륨, 진동, 방해 금지', box: Box(173, 1670, 450, 1703)),
      UiElement(label: '디스플레이', box: Box(156, 1790, 390, 1841)),
      UiElement(label: '어두운 테마, 글꼴 크기', box: Box(173, 1860, 471, 1893)),
      UiElement(label: '개인정보 보호', box: Box(173, 1979, 425, 2025)),
      UiElement(label: '권한, 계정 활동', box: Box(172, 2050, 376, 2084)),
    ],
  );

  static const chat = SampleAnswer(
    fileName: 'sample_chat.png',
    width: 1080,
    height: 2340,
    screenId: 'demo.chat',
    elements: [
      UiElement(label: '10:23', box: Box(45, 25, 123, 51)),
      UiElement(label: 'LTE 87%', box: Box(914, 25, 1037, 50)),
      UiElement(label: '홍길동 대화', box: Box(44, 116, 258, 161)),
      UiElement(label: '2026-10-23', box: Box(449, 250, 630, 277)),
      UiElement(label: '내일 예약 오후 3시 맞죠?', box: Box(82, 361, 489, 398)),
      UiElement(
        label: '네 맞아요. 연락은 010-1234-5678 로 주세요',
        box: Box(210, 492, 962, 533),
      ),
      UiElement(label: '사무실 번호는 02-123-4567 입니다', box: Box(223, 627, 814, 664)),
      UiElement(
        label: '환불은 110-123-456789 계좌로 보내 드릴게',
        box: Box(80, 762, 818, 799),
      ),
      UiElement(label: '요', box: Box(80, 824, 112, 854)),
      UiElement(
        label: '본인 확인용으로 900101-1234567 남겨 주세',
        box: Box(80, 954, 826, 991),
      ),
      UiElement(
        label: '메일은 gildong@example.com 입니다',
        box: Box(225, 1147, 897, 1191),
      ),
      UiElement(label: '메시지 입력', box: Box(59, 2216, 258, 2257)),
      UiElement(label: '보내기', box: Box(895, 2219, 996, 2255)),
    ],
    pii: [
      PiiCandidate(type: '휴대전화', masked: '010-****-**78', elementIndex: 5),
      PiiCandidate(type: '유선전화', masked: '02-***-**67', elementIndex: 6),
      PiiCandidate(type: '계좌번호 추정', masked: '110-***-****89', elementIndex: 7),
      PiiCandidate(
        type: '주민·외국인등록번호',
        masked: '900***-*****67',
        elementIndex: 9,
      ),
      PiiCandidate(
        type: '이메일',
        masked: 'gil****@*******.*om',
        elementIndex: 10,
      ),
    ],
  );

  static const all = [settings, chat];
}
