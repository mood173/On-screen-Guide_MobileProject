// 체험용 샘플 이미지 목록. 실제 갤러리 구현이 들어오기 전까지 가짜 갤러리·카메라가 돌려주는 사진이다.
// 이 사진의 "정답" 분석 결과는 가짜 분석기 쪽(analyze/data/sample_answers.dart)에 파일 이름으로 이어져 있다.

class SampleImage {
  const SampleImage({required this.id, required this.asset});

  /// 갤러리 목록 id ([GalleryItem.id])
  final String id;

  /// Flutter 에셋 경로. 앱 복사본을 만들 때 읽는다.
  final String asset;

  static const settings = SampleImage(
    id: 'settings',
    asset: 'assets/samples/sample_settings.png',
  );

  static const chat = SampleImage(
    id: 'chat',
    asset: 'assets/samples/sample_chat.png',
  );

  static const all = [settings, chat];
}
