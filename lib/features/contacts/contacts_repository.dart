import 'package:chat/core/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';

class ContactsRepository {
  final AppDatabase _db;

  ContactsRepository(this._db);

  Stream<List<Contact>> watchAllContacts() {
    return (_db.select(
      _db.contacts,
    )..where((row) => row.status.equals(ContactStatus.active.index))).watch();
  }

  Stream<Contact> watchContact(int contactId) {
    return (_db.select(
      _db.contacts,
    )..where((row) => row.id.equals(contactId))).watchSingle();
  }

  Future<int> addContact({
    required String alias,
    required String publicKey,
    int? disappearingAfterSeconds,
    ContactStatus status = ContactStatus.active,
    bool isQrInitiated = false,
  }) async {
    return await _db
        .into(_db.contacts)
        .insertOnConflictUpdate(
          ContactsCompanion.insert(
            alias: alias,
            publicKey: publicKey,
            disappearingAfterSeconds: Value(disappearingAfterSeconds),
            status: Value(status),
            isQrInitiated: Value(isQrInitiated),
          ),
        );
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

  Stream<List<Contact>> watchPendingInContacts() {
    return (_db.select(_db.contacts)
          ..where((row) => row.status.equals(ContactStatus.pendingIn.index)))
        .watch();
  }

  Stream<List<Contact>> watchBlockedContacts() {
    return (_db.select(
      _db.contacts,
    )..where((row) => row.status.equals(ContactStatus.blocked.index))).watch();
  }

  Future<void> updateContactStatus(int contactId, ContactStatus status) async {
    await (_db.update(_db.contacts)..where((row) => row.id.equals(contactId)))
        .write(ContactsCompanion(status: Value(status)));
  }

  Future<void> updateQrInitiated(int contactId, bool value) async {
    await (_db.update(_db.contacts)..where((row) => row.id.equals(contactId)))
        .write(ContactsCompanion(isQrInitiated: Value(value)));
  }
}

final contactsStreamProvider = StreamProvider<List<Contact>>((ref) {
  final repository = ref.watch(contactsRepositoryProvider);
  if (repository == null) return const Stream.empty();
  return repository.watchAllContacts();
});

final contactStreamProvider = StreamProvider.family<Contact, int>((
  ref,
  contactId,
) {
  final repository = ref.watch(contactsRepositoryProvider);
  if (repository == null) return const Stream.empty();
  return repository.watchContact(contactId);
});

final pendingInContactsProvider = StreamProvider<List<Contact>>((ref) {
  final repository = ref.watch(contactsRepositoryProvider);
  if (repository == null) return const Stream.empty();
  return repository.watchPendingInContacts();
});

final blockedContactsProvider = StreamProvider<List<Contact>>((ref) {
  final repository = ref.watch(contactsRepositoryProvider);
  if (repository == null) return const Stream.empty();
  return repository.watchBlockedContacts();
});
