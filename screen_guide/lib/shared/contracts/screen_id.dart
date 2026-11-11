/// 화면 ID. (기능·개념 정리 7장 화면 목록 = Figma「화면길잡이 · UI 설계서 v2 · Beta」프레임 이름)
///
/// [code]는 설계 문서와 Figma 프레임 이름 앞부분과 같다 (예: "H · 홈").
/// [figmaNode]는 그 프레임의 node-id. [figmaUrl]로 Figma에서 바로 열 수 있다.
/// D1~D5는 Figma에 같은 내용의 복사본이 여러 벌(1/5~1/8) 있어 처음 만든 15: 계열을 기준으로 한다.
enum ScreenId {
  // 홈
  h('H', '홈', '14:114'),

  // 카메라 입력
  cp('CP', '카메라 접근', '15:113'),
  c('C', '카메라 촬영', '15:119'),
  cr('CR', '촬영한 사진', '15:125'),
  ca('CA', '사진 분석 중', '15:131'),
  rc('RC', '카메라 분석 결과', '15:137'),

  // 갤러리 입력
  g('G', '최근 이미지', '15:143'),
  gs('GS', '이미지 선택', '15:149'),
  gr('GR', '선택한 이미지', '15:155'),
  ga('GA', '이미지 분석 중', '15:161'),
  rg('RG', '갤러리 분석 결과', '15:167'),

  // 단계별 안내
  d1('D1', '단계별 안내 · 1', '15:233'),
  d2('D2', '단계별 안내 · 2', '15:239'),
  d3('D3', '단계별 안내 · 3', '15:245'),
  d4('D4', '단계별 안내 · 4', '15:251'),
  d5('D5', '단계별 안내 · 5', '15:257'),
  done('DONE', '안내 완료', '15:293'),

  // 실시간 안내 (N01, 확장)
  lp('LP', '실시간 안내 설정', '15:173'),
  l('L', '실시간 인식 (닫힘)', '15:179'),
  lo('LO', '실시간 인식 (열림)', '15:185'),
  lt('LT', '원하는 기능', '15:191'),
  lx('LX', '현재 화면 스캔', '15:197'),
  lg1('LG1', '실시간 안내 · 1', '15:203'),
  lg2('LG2', '실시간 안내 · 2', '15:209'),
  lg3('LG3', '실시간 안내 · 3', '15:215'),
  lg4('LG4', '실시간 안내 · 4', '15:221'),
  lg5('LG5', '실시간 안내 · 5', '15:227'),

  // 공유·기록·설정
  p('P', '공유 전 확인', '15:263'),
  share('SHARE', '공유하기', '15:299'),
  history('HISTORY', '내 안내 기록', '15:269'),
  settings('SETTINGS', '설정', '15:275'),

  // 복구
  deny('DENY', '권한이 필요해요', '15:287'),
  e('E', '다시 시도', '15:281');

  const ScreenId(this.code, this.title, this.figmaNode);

  /// 설계 문서의 화면 ID (H, CP, D1 …)
  final String code;

  /// Figma 프레임 이름의 뒷부분
  final String title;

  /// Figma node-id ("14:114" 형식)
  final String figmaNode;

  static const figmaFileKey = 'QqKYcVCHek9vY3pOLKf6cF';

  /// Figma에서 이 화면 프레임을 여는 주소 (팀원 계정 로그인 필요)
  String get figmaUrl =>
      'https://www.figma.com/design/$figmaFileKey/?node-id=${figmaNode.replaceAll(':', '-')}';

  static ScreenId? fromCode(String code) {
    for (final s in ScreenId.values) {
      if (s.code == code) return s;
    }
    return null;
  }
}
