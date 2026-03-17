import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';

class ContactsRepository {
  final AppDatabase _db;

  ContactsRepository(this._db);

  Stream<List<Contact>> watchAllContacts() {
    return _db.select(_db.contacts).watch();
  }

  Stream<Contact> watchContact(int contactId) {
    return (_db.select(
      _db.contacts,
    )..where((row) => row.id.equals(contactId))).watchSingle();
  }

  Future<int> addContact({
    required String alias,
    required String publicKey,
  }) async {
    return await _db
        .into(_db.contacts)
        .insert(ContactsCompanion.insert(alias: alias, publicKey: publicKey));
  }

  Future<void> deleteContact(int id) async {
    await (_db.delete(_db.contacts)..where((row) => row.id.equals(id))).go();
  }

  Future<Contact?> getContactByPublicKey(String publicKey) async {
    return await (_db.select(
      _db.contacts,
    )..where((row) => row.publicKey.equals(publicKey))).getSingleOrNull();
  }

  Future<void> updateAlias(int contactId, String newAlias) async {
    await (_db.update(_db.contacts)..where((row) => row.id.equals(contactId)))
        .write(ContactsCompanion(alias: Value(newAlias)));
  }

  Future<void> updateDisappearingTimer(int contactId, int? seconds) async {
    await (_db.update(_db.contacts)..where((row) => row.id.equals(contactId)))
        .write(ContactsCompanion(disappearingAfterSeconds: Value(seconds)));
  }

  Future<List<Contact>> getContactsWithDisappearing() async {
    return (_db.select(
      _db.contacts,
    )..where((row) => row.disappearingAfterSeconds.isNotNull())).get();
  }
}

final contactsRepositoryProvider = FutureProvider<ContactsRepository>((
  ref,
) async {
  final db = await ref.watch(databaseProvider.future);
  return ContactsRepository(db);
});

final contactsStreamProvider = StreamProvider<List<Contact>>((ref) async* {
  final repository = await ref.watch(contactsRepositoryProvider.future);
  yield* repository.watchAllContacts();
});

final contactStreamProvider = StreamProvider.family<Contact, int>((
  ref,
  contactId,
) async* {
  final repo = await ref.watch(contactsRepositoryProvider.future);
  yield* repo.watchContact(contactId);
});
