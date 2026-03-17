import 'package:chat/core/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';

class MessagesRepository {
  final AppDatabase _db;

  MessagesRepository(this._db);

  Stream<List<Message>> watchMessagesForContact(int contactId) {
    return (_db.select(_db.messages)
          ..where((row) => row.contactId.equals(contactId))
          ..orderBy([
            (row) => OrderingTerm(
              expression: row.timestamp,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<void> saveMessage({
    required String messageId,
    required int contactId,
    required String content,
    required bool isFromMe,
  }) async {
    await _db
        .into(_db.messages)
        .insert(
          MessagesCompanion.insert(
            messageId: messageId,
            contactId: contactId,
            content: content,
            isFromMe: isFromMe,
            status: isFromMe ? MessageStatus.sending : MessageStatus.delivered,
          ),
        );
  }

  Future<List<Message>> getUnreadMessages(int contactId) async {
    return (_db.select(_db.messages)
          ..where((row) => row.contactId.equals(contactId))
          ..where((row) => row.isFromMe.equals(false))
          ..where((row) => row.status.equals(MessageStatus.delivered.index)))
        .get();
  }

  Future<void> updateMessageStatus(
    List<String> messageIds,
    MessageStatus newStatus,
    DateTime? readAt,
  ) async {
    if (messageIds.isEmpty) return;
    await (_db.update(
      _db.messages,
    )..where((row) => row.messageId.isIn(messageIds))).write(
      MessagesCompanion(
        status: Value(newStatus),
        readAt: readAt != null ? Value(readAt) : const Value.absent(),
      ),
    );
  }

  Future<void> deleteMessagesOlderThan(int contactId, DateTime cutoff) async {
    await (_db.delete(_db.messages)..where(
          (row) =>
              row.contactId.equals(contactId) &
              row.timestamp.isSmallerThanValue(cutoff),
        ))
        .go();
  }
}

final chatRepositoryProvider = FutureProvider<MessagesRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return MessagesRepository(db);
});

final chatStreamProvider = StreamProvider.family<List<Message>, int>((
  ref,
  contactId,
) async* {
  final repository = await ref.watch(chatRepositoryProvider.future);
  yield* repository.watchMessagesForContact(contactId);
});
