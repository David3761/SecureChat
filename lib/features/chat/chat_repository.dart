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
    MessageStatus? status,
  }) async {
    await _db
        .into(_db.messages)
        .insertOnConflictUpdate(
          MessagesCompanion.insert(
            messageId: messageId,
            contactId: contactId,
            content: content,
            isFromMe: isFromMe,
            status:
                status ??
                (isFromMe ? MessageStatus.sending : MessageStatus.delivered),
          ),
        );
  }

  Future<List<Message>> getPendingMessagesForContact(int contactId) {
    return (_db.select(_db.messages)
          ..where(
            (row) =>
                row.contactId.equals(contactId) &
                row.status.equals(MessageStatus.pendingAcceptance.index),
          )
          ..orderBy([
            (row) =>
                OrderingTerm(expression: row.timestamp, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<void> dropExpiredPendingMessages() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    await (_db.update(_db.messages)
          ..where(
            (row) =>
                row.status.equals(MessageStatus.pendingAcceptance.index) &
                row.timestamp.isSmallerThanValue(cutoff),
          ))
        .write(const MessagesCompanion(status: Value(MessageStatus.failed)));
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

  Future<Message?> getMessageById(String messageId) async {
    return (_db.select(
      _db.messages,
    )..where((row) => row.messageId.equals(messageId))).getSingleOrNull();
  }
}

final chatStreamProvider = StreamProvider.family<List<Message>, int>((
  ref,
  contactId,
) {
  final repository = ref.watch(chatRepositoryProvider);
  if (repository == null) return const Stream.empty();
  return repository.watchMessagesForContact(contactId);
});
