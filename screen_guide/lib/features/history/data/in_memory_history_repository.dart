// 최정혁(데이터·입출력)이 진짜 구현을 넣기 전까지 쓰는 가짜 구현. app/bootstrap.dart에서 진짜로 바꿔 끼운다.

import 'package:screen_guide/features/history/domain/history.dart';

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
