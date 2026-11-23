import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/history/domain/history.dart';

/// 기록 DB를 여는 함수. 기본은 앱 전용 DB 폴더의 파일, 시험에서는 메모리 DB를 넘긴다.
typedef HistoryDbOpener = Future<Database> Function();

/// [HistoryRepository]의 진짜 구현. ── 최정혁 (협업규격_최종 4.3 #6)
///
/// 앱 전용 DB 폴더(`getDatabasesPath()`, Android `/data/user/0/<앱>/databases`)의 SQLite 파일에
/// 안내 기록을 저장한다. 앱을 껐다 켜도 남는다 (MP3 통과 기준).
///
/// 표는 [HistoryEntry]와 열이 1:1이다. **이미지 경로·화면에서 읽은 글자·개인정보 후보 값을 담는 열은 없다**
/// (협업규격_최종 3.2, 기능별_검토_결론 6장). 개인정보는 유형 이름만 저장한다.
///
/// 예외를 밖으로 던지지 않는다: 저장·삭제 실패는 조용히 끝나고, 목록은 빈 목록, 한 건 읽기는 null.
/// (포트에 결과 값이 없어 흐름은 저장 실패를 모른다 — 설계 문서 9장 5번, 지형주와 정할 일)
class SqliteHistoryRepository implements HistoryRepository {
  SqliteHistoryRepository({HistoryDbOpener? open}) : _opener = open ?? openFile;

  static const fileName = 'screen_guide_history.db';
  static const table = 'history_entry';
  static const schemaVersion = 1;

  static const _create =
      '''
CREATE TABLE $table (
  id                TEXT PRIMARY KEY,
  action_id         TEXT NOT NULL,
  action_title      TEXT NOT NULL,
  step_instructions TEXT NOT NULL,
  input             TEXT NOT NULL,
  created_at        INTEGER NOT NULL,
  pii_types         TEXT NOT NULL
)''';

  /// 앱 전용 DB 폴더의 파일을 연다. 처음이면 표를 만든다.
  static Future<Database> openFile() async => openDatabase(
    p.join(await getDatabasesPath(), fileName),
    version: schemaVersion,
    onCreate: createSchema,
  );

  /// 표 만들기 (시험의 메모리 DB에서도 쓴다)
  static Future<void> createSchema(Database db, int version) =>
      db.execute(_create);

  final HistoryDbOpener _opener;
  Future<Database>? _db;

  Future<Database> _open() => _db ??= _opener().catchError((Object e) {
    _db = null; // 다음 호출 때 다시 열어 본다
    throw e;
  });

  @override
  Future<void> save(HistoryEntry entry) async {
    try {
      await (await _open()).insert(
        table,
        toRow(entry),
        conflictAlgorithm: ConflictAlgorithm.replace, // 같은 id면 덮어쓴다
      );
    } catch (_) {
      // 저장 실패 — 흐름을 막지 않는다
    }
  }

  @override
  Future<List<HistoryEntry>> list() async {
    try {
      final rows = await (await _open()).query(
        table,
        orderBy: 'created_at DESC, id DESC',
      );
      return [for (final r in rows) ?fromRow(r)];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<HistoryEntry?> get(String id) async {
    try {
      final rows = await (await _open()).query(
        table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : fromRow(rows.single);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (await _open()).delete(table, where: 'id = ?', whereArgs: [id]);
    } catch (_) {
      // 지우지 못함 — 흐름을 막지 않는다
    }
  }

  /// 시험·앱 종료용. 포트 메서드가 아니다. 열지 못한 상태여도 예외 없이 끝난다.
  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db == null) return;
    try {
      await (await db).close();
    } catch (_) {
      // 열지 못했거나 이미 닫힘
    }
  }

  static Map<String, Object?> toRow(HistoryEntry e) => {
    'id': e.id,
    'action_id': e.actionId,
    'action_title': e.actionTitle,
    'step_instructions': jsonEncode(e.stepInstructions),
    'input': e.input.name,
    'created_at': e.createdAt.millisecondsSinceEpoch,
    'pii_types': jsonEncode(e.piiTypes),
  };

  /// 읽을 수 없는 줄(손상·모르는 입력 방식)은 null — 목록에서 빠진다.
  static HistoryEntry? fromRow(Map<String, Object?> r) {
    try {
      return HistoryEntry(
        id: r['id']! as String,
        actionId: r['action_id']! as String,
        actionTitle: r['action_title']! as String,
        stepInstructions: (jsonDecode(
          r['step_instructions']! as String,
        ) as List).cast<String>(),
        input: InputKind.values.byName(r['input']! as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at']! as int),
        piiTypes: (jsonDecode(r['pii_types']! as String) as List)
            .cast<String>(),
      );
    } catch (_) {
      return null;
    }
  }
}
