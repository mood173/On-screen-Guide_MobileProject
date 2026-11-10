// 팀원 3이 진짜 구현을 넣기 전까지 쓰는 가짜 구현 모음. bootstrap.dart에서 하나씩 진짜로 바꿔 끼운다.
// ignore_for_file: prefer_initializing_formals

import '../domain/history.dart';
import '../domain/image_input.dart';
import '../domain/share_and_update.dart';
import 'image_files.dart';
import 'sample_images.dart';

/// 메모리에만 두는 안내 기록. 앱을 끄면 사라진다.
class InMemoryHistoryRepository implements HistoryRepository {
  final _items = <HistoryEntry>[];

  @override
  Future<void> save(HistoryEntry entry) async {
    _items.removeWhere((e) => e.id == entry.id);
    _items.add(entry);
  }

  @override
  Future<List<HistoryEntry>> list() async =>
      [..._items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<HistoryEntry?> get(String id) async {
    for (final e in _items) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<void> delete(String id) async => _items.removeWhere((e) => e.id == id);
}

/// 가짜 사진 가져오기: 갤러리·카메라 모두 [sample]을 앱 복사본으로 돌려준다.
/// [status]를 바꾸면 취소·권한 거부·읽기 실패 화면을 시험할 수 있다.
class FakeImageInput implements ImageInput {
  FakeImageInput({
    ImageFiles files = const AssetPathImageFiles(),
    this.sample = SampleImage.settings,
    this.status = PickStatus.ok,
  }) : _files = files;

  final ImageFiles _files;
  SampleImage sample;
  PickStatus status;

  Future<PickedImage> _pick(String input) async {
    if (status != PickStatus.ok) return PickedImage.failed(status);
    final path = await _files.prepare(sample);
    return PickedImage(
      status: PickStatus.ok,
      path: path,
      input: input,
      appOwned: true,
    );
  }

  @override
  Future<PickedImage> pickFromGallery() => _pick('gallery');

  @override
  Future<PickedImage> takePhoto() => _pick('camera');

  @override
  Future<void> release(PickedImage image) async {
    if (image.appOwned && image.path != null) await _files.release(image.path!);
  }
}

/// 가짜 공유: 보낸 텍스트를 기억만 한다.
class FakeSharer implements Sharer {
  final sent = <String>[];

  @override
  Future<bool> shareText(String text) async {
    sent.add(text);
    return true;
  }
}

/// 가짜 기능 맵 갱신: 항상 최신이라고 답한다.
class FakeMapUpdater implements MapUpdater {
  @override
  Future<MapUpdateResult> checkForUpdate() async =>
      const MapUpdateResult(MapUpdateStatus.upToDate, 'demo');
}
