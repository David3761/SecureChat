import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/providers.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyProfileRepository {
  final AppDatabase _db;

  MyProfileRepository(this._db);

  Future<Uint8List?> getProfilePicture() {
    return (_db.select(_db.myProfile)..where((r) => r.id.equals(1)))
        .getSingleOrNull()
        .then((row) => row?.profilePicture);
  }

  Stream<Uint8List?> watchProfilePicture() {
    return (_db.select(_db.myProfile)..where((r) => r.id.equals(1)))
        .watchSingleOrNull()
        .map((row) => row?.profilePicture);
  }

  Future<void> saveProfilePicture(Uint8List? bytes) async {
    await _db
        .into(_db.myProfile)
        .insert(
          MyProfileCompanion.insert(
            id: const Value(1),
            profilePicture: Value(bytes),
          ),
          onConflict: DoUpdate(
            (_) => MyProfileCompanion(profilePicture: Value(bytes)),
            target: [_db.myProfile.id],
          ),
        );
  }
}

final myProfileRepositoryProvider = Provider<MyProfileRepository?>((ref) {
  final db = ref.watch(databaseProvider).asData?.value;
  return db != null ? MyProfileRepository(db) : null;
});

final myProfilePictureProvider = StreamProvider<Uint8List?>((ref) {
  final repo = ref.watch(myProfileRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchProfilePicture();
});
