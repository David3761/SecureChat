import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Contacts, Messages])
class AppDatabase extends _$AppDatabase {
  AppDatabase(String publicKey, String encryptionKey)
    : super(_openConnection(publicKey, encryptionKey)) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(messages);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection(String publicKey, String encryptionKey) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'secure_chat_$publicKey.sqlite'));

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        final escapedKey = encryptionKey.replaceAll("'", "''");

        rawDb.execute("PRAGMA key = '$escapedKey';");

        rawDb.execute("SELECT count(*) FROM sqlite_master;");
      },
    );
  });
}
