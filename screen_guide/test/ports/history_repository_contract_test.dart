import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:screen_guide/features/history/data/sqlite_history_repository.dart';

import 'port_contracts.dart';

// 진짜 HistoryRepository(SqliteHistoryRepository)가 기록 공용 시험을 통과하는지.
// PC에서는 sqflite_common_ffi의 메모리 DB로 같은 SQL을 돌린다. 시험마다 새 DB.
void main() {
  sqfliteFfiInit();

  historyRepositoryContract(
    'SQLite',
    () => SqliteHistoryRepository(
      open: () => databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: SqliteHistoryRepository.schemaVersion,
          onCreate: SqliteHistoryRepository.createSchema,
          singleInstance: false,
        ),
      ),
    ),
  );
}
