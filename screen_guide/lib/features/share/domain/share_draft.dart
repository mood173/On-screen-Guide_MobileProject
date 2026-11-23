import 'package:screen_guide/shared/contracts/screen_id.dart';

/// 공유할 내용 한 묶음 (11/22 결정 ①). P는 [candidates]만, SHARE는 [title]·[steps]로 보낼 글을 만든다.
///
/// 이미지·화면에서 읽은 글자는 담지 않는다 — 단계 문구는 기능 맵에 사람이 써 둔 글이다 (검토 결론 5장).
/// 흐름(app)과 P 화면(features/privacy/ui)이 함께 쓰는 모델이라 흐름 파일이 아니라 공유 도메인에 둔다 (E-13).
class ShareDraft {
  const ShareDraft({
    required this.title,
    required this.steps,
    required this.candidates,
    required this.from,
    this.historyId,
  });

  /// 기능 제목
  final String title;

  /// 단계 문구
  final List<String> steps;

  /// 개인정보 후보 (P가 보여 준다)
  final List<ShareCandidate> candidates;

  /// 들어온 곳: [ScreenId.done] 또는 [ScreenId.history]. 뒤로 갈 곳.
  final ScreenId from;

  /// 기록에서 왔을 때 그 기록 id (돌아가서 다시 펼치려고)
  final String? historyId;
}

/// P에 보이는 개인정보 후보 한 줄. 기록에서 왔으면 가린 값이 없다(null).
class ShareCandidate {
  const ShareCandidate({required this.type, this.masked});

  /// 개인정보 유형 이름 (piiTypes 9개 중 하나)
  final String type;

  /// 가린 값. 기록에서 온 후보는 저장하지 않으므로 null.
  final String? masked;
}
