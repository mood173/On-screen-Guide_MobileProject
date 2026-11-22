import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/history/data/sqlite_history_repository.dart';
import 'package:screen_guide/features/history/domain/history.dart';

// SqliteHistoryRepository: PC에서는 sqflite_common_ffi(SQLite)로 같은 SQL을 돌려 본다.
// 앱을 껐다 켜도 남는지는 파일 DB로 다시 열어 확인하고, 실제 기기는 에뮬레이터에서 확인한다.

HistoryEntry entry(
  String id, {
  int minute = 0,
  InputKind input = InputKind.camera,
}) => HistoryEntry(
  id: id,
  actionId: 'chat.send',
  actionTitle: '메시지 보내기',
  stepInstructions: const ['메시지 입력 칸을 눌러주세요', '보내기를 눌러주세요'],
  input: input,
  createdAt: DateTime(2026, 11, 21, 10, minute),
  piiTypes: const ['휴대전화', '이메일'],
);

Future<Database> memoryDb() => databaseFactoryFfi.openDatabase(
  inMemoryDatabasePath,
  options: OpenDatabaseOptions(
    version: SqliteHistoryRepository.schemaVersion,
    onCreate: SqliteHistoryRepository.createSchema,
    singleInstance: false, // 시험마다 새 DB
  ),
);

void main() {
  sqfliteFfiInit();

  test('저장한 한 건의 모든 칸을 그대로 읽는다', () async {
    final repo = SqliteHistoryRepository(open: memoryDb);
    await repo.save(entry('a', input: InputKind.gallery));
    final got = (await repo.get('a'))!;
    expect(got.actionId, 'chat.send');
    expect(got.actionTitle, '메시지 보내기');
    expect(got.stepInstructions, ['메시지 입력 칸을 눌러주세요', '보내기를 눌러주세요']);
    expect(got.input, InputKind.gallery);
    expect(got.createdAt, DateTime(2026, 11, 21, 10));
    expect(got.piiTypes, ['휴대전화', '이메일']);
    await repo.close();
  });

  test('표에 이미지·인식 글자·가린 값 열이 없다 (열 7개가 HistoryEntry와 1:1)', () async {
    final db = await memoryDb();
    final cols = (await db.rawQuery(
      'PRAGMA table_info(${SqliteHistoryRepository.table})',
    )).map((r) => r['name']! as String).toList();
    expect(cols, [
      'id',
      'action_id',
      'action_title',
      'step_instructions',
      'input',
      'created_at',
      'pii_types',
    ]);
    for (final c in cols) {
      for (final bad in ['path', 'image', 'ocr', 'masked', 'label', 'text']) {
        expect(c.contains(bad), isFalse, reason: c);
      }
    }
    await db.close();
  });

  test('앱을 껐다 켜도 남는다: 파일 DB를 닫고 다시 열어 읽는다', () async {
    final dir = await Directory.systemTemp.createTemp('history_test_');
    addTearDown(() => dir.delete(recursive: true));
    final file = '${dir.path}/h.db';
    Future<Database> open() => databaseFactoryFfi.openDatabase(
      file,
      options: OpenDatabaseOptions(
        version: SqliteHistoryRepository.schemaVersion,
        onCreate: SqliteHistoryRepository.createSchema,
      ),
    );

    final first = SqliteHistoryRepository(open: open);
    await first.save(entry('a'));
    await first.close();

    final second = SqliteHistoryRepository(open: open);
    expect((await second.get('a'))?.actionId, 'chat.send');
    expect(await second.list(), hasLength(1));
    await second.close();
  });

  test('DB를 열지 못하면 예외 없이: 저장·삭제는 조용히, 목록은 빈 목록, 한 건은 null', () async {
    final repo = SqliteHistoryRepository(
      open: () async => throw const FileSystemException('열 수 없음'),
    );
    await repo.save(entry('a'));
    await repo.delete('a');
    expect(await repo.list(), isEmpty);
    expect(await repo.get('a'), isNull);
    await repo.close(); // 열지 못한 상태에서 닫아도 예외 없음
  });

  test('DB를 처음 열지 못해도 다음 호출 때 다시 연다', () async {
    var calls = 0;
    final repo = SqliteHistoryRepository(
      open: () async {
        calls++;
        if (calls == 1) throw const FileSystemException('잠깐 실패');
        return memoryDb();
      },
    );
    await repo.save(entry('a')); // 실패
    await repo.save(entry('b')); // 다시 열고 성공
    expect((await repo.list()).map((e) => e.id), ['b']);
    await repo.close();
  });

  test('손상된 줄·모르는 입력 방식은 목록에서 빠지고 나머지는 읽힌다', () async {
    final db = await memoryDb();
    final repo = SqliteHistoryRepository(open: () async => db);
    await repo.save(entry('ok'));
    await db.insert(SqliteHistoryRepository.table, {
      ...SqliteHistoryRepository.toRow(entry('bad-input', minute: 5)),
      'input': 'live',
    });
    await db.insert(SqliteHistoryRepository.table, {
      ...SqliteHistoryRepository.toRow(entry('bad-json', minute: 6)),
      'step_instructions': '{not json',
    });
    expect((await repo.list()).map((e) => e.id), ['ok']);
    expect(await repo.get('bad-json'), isNull);
    await repo.close();
  });

  test('같은 시각이면 id 순으로 정렬이 일정하다', () async {
    final repo = SqliteHistoryRepository(open: memoryDb);
    await repo.save(entry('a'));
    await repo.save(entry('b'));
    expect((await repo.list()).map((e) => e.id), ['b', 'a']);
    await repo.close();
  });
}
