// 협업규격 4.2 5번 "확인 화면 없이 공유되는 길 0개", 검토 결론 5장 필수, 역할설계 11/23~29 "공유 경로 전수 시험".
//
// 방법: 홈에서 시작해 흐름이 갈 수 있는 상태를 **모두** 찾아간다 (너비 우선 탐색).
// - 상태 = 화면 + 흐름의 몇 가지 값 (아래 _key). 같은 상태는 한 번만 펼친다 → 끝이 있다.
// - 각 상태에서 지금 열린 버튼을 하나씩 다 눌러 본다 (인자가 있는 버튼은 고를 수 있는 값마다).
// - 거기에 더해, 열려 있든 아니든 "보내기"(shareSend)를 직접 한 번 눌러 본다.
// - 버튼은 화면이 하는 것처럼 dispatch로만 누른다 (관문을 거치는 진짜 길).
// 흐름 객체를 복사할 수 없으므로, 상태마다 홈에서 그 상태까지의 버튼 순서를 다시 눌러 되살린다.
//
// 지키는 규칙: 공유가 한 번 일어날 때마다, 그 버튼 순서에서 마지막 "공유하기"(sharePrepare) 뒤에
// "확인했어요"(shareConfirm)가 있어야 한다. 즉 P에서 확인하지 않고 보내진 길이 하나도 없어야 한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/app/guide_flow.dart';
import 'package:screen_guide/features/analyze/data/fake_analyzer.dart';
import 'package:screen_guide/features/capture/data/fake_input.dart';
import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/guidance_map/domain/guidance.dart';
import 'package:screen_guide/features/history/data/in_memory_history_repository.dart';
import 'package:screen_guide/features/share/data/fake_sharer.dart';
import 'package:screen_guide/shared/contracts/action_id.dart';
import 'package:screen_guide/shared/contracts/error_code.dart';
import 'package:screen_guide/shared/contracts/screen_id.dart';

import '../support/test_flow.dart';

/// 버튼 한 번 (인자 포함)
typedef _Press = (ActionId, Object?);

/// 탐색 한 번의 결과
class _Report {
  final visited = <ScreenId>{};
  var states = 0;
  var sends = 0;

  /// 기록 화면에서 들어가 보낸 횟수 (두 들어오는 곳을 모두 가 봤는지)
  var sendsFromHistory = 0;
  final badPaths = <List<_Press>>[];
}

/// 한 가지 조건(가짜 입력·분석기 설정)에서 갈 수 있는 상태를 모두 찾아가며 규칙을 확인한다.
Future<_Report> _explore({
  PickStatus galleryAccess = PickStatus.ok,
  PickStatus cameraStatus = PickStatus.ok,
  ErrorCode? analyzeFails,
}) async {
  final report = _Report();

  /// 새 흐름을 만들고 [path]를 처음부터 다시 누른다. 흐름, 공유 기록, 기록 저장소를 돌려준다.
  Future<(GuideFlow, FakeSharer, InMemoryHistoryRepository)> replay(
    List<_Press> path,
  ) async {
    final sharer = FakeSharer();
    final history = InMemoryHistoryRepository();
    final f = testFlow(
      sharer: sharer,
      history: history,
      gallery: FakeGalleryInput(
        access: galleryAccess,
        loadThumbnail: noThumbnail,
      ),
      camera: FakeCameraInput(status: cameraStatus),
      analyzer: FakeAnalyzer(delay: Duration.zero, failWith: analyzeFails),
    );
    for (final (id, arg) in path) {
      await f.dispatch(id, arg);
    }
    return (f, sharer, history);
  }

  /// 이 버튼 순서로 보낸 것이 규칙에 맞는가: 마지막 공유하기 뒤에 확인했어요가 있어야 한다.
  bool confirmedBeforeSend(List<_Press> path) {
    final lastPrepare = path.lastIndexWhere(
      (p) => p.$1 == ActionId.sharePrepare,
    );
    if (lastPrepare < 0) return false;
    return path.skip(lastPrepare + 1).any((p) => p.$1 == ActionId.shareConfirm);
  }

  /// 지금 상태에서 눌러 볼 버튼들 (인자가 있는 버튼은 고를 수 있는 값마다)
  List<_Press> pressesAt(GuideFlow f) => [
    for (final id in f.allowed)
      ...switch (id) {
        ActionId.capturePick => [for (final g in f.galleryItems) (id, g.id)],
        ActionId.guideStart => [for (final a in f.availableActions) (id, a)],
        ActionId.historyOpen ||
        ActionId.historyDelete => [for (final e in f.historyItems) (id, e.id)],
        _ => [(id, null)],
      },
    // 열려 있지 않아도 "보내기"를 직접 눌러 본다 (관문이 막는지)
    if (!f.allowed.contains(ActionId.shareSend)) (ActionId.shareSend, null),
  ];

  /// 같은 상태를 두 번 펼치지 않기 위한 열쇠: 화면 + 공유·기록·안내에 영향을 주는 값 + 저장된 기록 수.
  /// 저장된 기록 수가 없으면 "저장 → 홈"이 처음 홈과 같은 상태로 보여 기록에서 공유하는 길을 못 찾는다
  /// (점검 실험에서 발견: 기록 화면에 보내기 구멍을 내도 시험이 통과했다).
  Future<String> key(GuideFlow f, InMemoryHistoryRepository h) async => [
    (await h.list()).length,
    f.screen.name,
    f.shareConfirmed,
    f.shareDraft?.from.name,
    f.input?.name,
    f.selectedId, // 목록에서 고른 칸 (설정·대화 샘플이 다른 길로 간다)
    f.picked?.path, // 가져온 사진
    f.result?.screenId,
    f.error?.name,
    f.action?.actionId,
    f.step,
    f.openedEntry?.id,
    f.historyItems.length,
    f.deniedInput?.name,
  ].join('|');

  final seen = <String>{};
  final queue = <List<_Press>>[[]];
  while (queue.isNotEmpty) {
    final path = queue.removeAt(0);
    final (f, _, h) = await replay(path);
    if (!seen.add(await key(f, h))) continue;
    report.states++;
    report.visited.add(f.screen);

    for (final press in pressesAt(f)) {
      // 그 상태를 새로 되살리고 버튼 하나만 더 누른다 → "이 한 번"에 보내졌는지만 센다
      // (앞에서 정상으로 보낸 기록은 세지 않는다)
      final (g, sharer, gh) = await replay(path);
      final before = sharer.sent.length;
      await g.dispatch(press.$1, press.$2);
      final next = [...path, press];
      if (sharer.sent.length > before) {
        report.sends++;
        final last = next.lastIndexWhere((p) => p.$1 == ActionId.sharePrepare);
        if (last > 0 && next[last - 1].$1 == ActionId.historyOpen) {
          report.sendsFromHistory++;
        }
        if (!confirmedBeforeSend(next)) report.badPaths.add(next);
      }
      if (!seen.contains(await key(g, gh))) queue.add(next);
    }
  }
  return report;
}

/// 실패했을 때 읽기 좋게: 기능은 이름(actionId)으로
String _show(List<_Press> path) => path
    .map((p) {
      final arg = p.$2 is GuideAction ? (p.$2 as GuideAction).actionId : p.$2;
      return arg == null ? p.$1.name : '${p.$1.name}($arg)';
    })
    .join(' → ');

void main() {
  test('기본 (권한 허용): 확인 화면 없이 공유되는 길 0개', () async {
    final r = await _explore();
    expect(r.badPaths.map(_show), isEmpty);
    // 탐색이 헛돌지 않았는지: 공유까지 실제로 가 봤고, 보낸 적이 있다
    expect(
      r.visited,
      containsAll([
        ScreenId.d2, // 두 단계 기능(대화 샘플)까지
        ScreenId.done,
        ScreenId.history,
        ScreenId.p,
        ScreenId.share,
      ]),
    );
    expect(r.sends, greaterThan(0));
    expect(r.sendsFromHistory, greaterThan(0), reason: '기록에서 들어가 보낸 길도 가 봤다');
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('권한 거부 (갤러리·카메라): 확인 화면 없이 공유되는 길 0개', () async {
    final r = await _explore(
      galleryAccess: PickStatus.permissionDenied,
      cameraStatus: PickStatus.permissionDenied,
    );
    expect(r.badPaths.map(_show), isEmpty);
    expect(r.visited, contains(ScreenId.deny));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('분석 실패: 확인 화면 없이 공유되는 길 0개 (오류 화면 E 포함)', () async {
    final r = await _explore(analyzeFails: ErrorCode.analysisFailed);
    expect(r.badPaths.map(_show), isEmpty);
    expect(r.visited, contains(ScreenId.e));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
