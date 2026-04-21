import 'package:chat/core/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';

class GroupRepository {
  final AppDatabase _db;

  GroupRepository(this._db);

  Stream<List<Group>> watchAllGroups() {
    return (_db.select(_db.groups)..orderBy([
          (row) =>
              OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<Group?> getGroupById(String groupId) {
    return (_db.select(
      _db.groups,
    )..where((row) => row.groupId.equals(groupId))).getSingleOrNull();
  }

  Future<void> createGroup({
    required String groupId,
    required String? name,
  }) async {
    await _db
        .into(_db.groups)
        .insertOnConflictUpdate(
          GroupsCompanion.insert(groupId: groupId, name: Value(name)),
        );
  }

  Future<void> deleteGroup(String groupId) async {
    await (_db.delete(
      _db.groups,
    )..where((row) => row.groupId.equals(groupId))).go();
    await (_db.delete(
      _db.groupMembers,
    )..where((row) => row.groupId.equals(groupId))).go();
    await (_db.delete(
      _db.groupMessages,
    )..where((row) => row.groupId.equals(groupId))).go();
  }

  Future<void> addMember({
    required String groupId,
    required String publicKey,
    required String alias,
    required bool isAdmin,
  }) async {
    await _db
        .into(_db.groupMembers)
        .insertOnConflictUpdate(
          GroupMembersCompanion.insert(
            groupId: groupId,
            publicKey: publicKey,
            alias: alias,
            isAdmin: Value(isAdmin),
          ),
        );
  }

  Future<List<GroupMember>> getMembersForGroup(String groupId) {
    return (_db.select(
      _db.groupMembers,
    )..where((row) => row.groupId.equals(groupId))).get();
  }

  Stream<List<GroupMember>> watchMembersForGroup(String groupId) {
    return (_db.select(
      _db.groupMembers,
    )..where((row) => row.groupId.equals(groupId))).watch();
  }

  Future<GroupMember?> getMember(String groupId, String publicKey) {
    return (_db.select(_db.groupMembers)..where(
          (row) =>
              row.groupId.equals(groupId) & row.publicKey.equals(publicKey),
        ))
        .getSingleOrNull();
  }

  Stream<List<GroupMessage>> watchMessagesForGroup(String groupId) {
    return (_db.select(_db.groupMessages)
          ..where((row) => row.groupId.equals(groupId))
          ..orderBy([
            (row) => OrderingTerm(
              expression: row.timestamp,
              mode: OrderingMode.desc,
            ),
            (row) => OrderingTerm(
              expression: row.id,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<GroupMessage?> getLatestMessage(String groupId) {
    return (_db.select(_db.groupMessages)
          ..where((row) => row.groupId.equals(groupId))
          ..orderBy([
            (row) => OrderingTerm(
              expression: row.timestamp,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> saveGroupMessage({
    required String messageId,
    required String groupId,
    required String senderPubKey,
    required String content,
    required bool isFromMe,
  }) async {
    await _db
        .into(_db.groupMessages)
        .insertOnConflictUpdate(
          GroupMessagesCompanion.insert(
            messageId: messageId,
            groupId: groupId,
            senderPubKey: senderPubKey,
            content: content,
            isFromMe: isFromMe,
            status: isFromMe ? MessageStatus.sending : MessageStatus.delivered,
          ),
        );
  }

  Future<void> removeMember(String groupId, String publicKey) async {
    await (_db.delete(_db.groupMembers)
          ..where(
            (row) =>
                row.groupId.equals(groupId) & row.publicKey.equals(publicKey),
          ))
        .go();
  }

  Future<void> updateGroupName(String groupId, String? name) async {
    await (_db.update(_db.groups)..where((row) => row.groupId.equals(groupId)))
        .write(GroupsCompanion(name: Value(name)));
  }

  Future<void> leaveGroup(String groupId, String myPubKey) async {
    await removeMember(groupId, myPubKey);
    final remaining = await getMembersForGroup(groupId);
    if (remaining.isEmpty) {
      await deleteGroup(groupId);
    }
  }

  Future<void> updateGroupMessageStatus(
    List<String> messageIds,
    MessageStatus status,
  ) async {
    if (messageIds.isEmpty) return;
    await (_db.update(_db.groupMessages)
          ..where((row) => row.messageId.isIn(messageIds)))
        .write(GroupMessagesCompanion(status: Value(status)));
  }

  Future<void> upsertReadReceipt({
    required String groupId,
    required String memberPubKey,
    required String lastReadMessageId,
  }) async {
    await _db.into(_db.groupReadReceipts).insert(
      GroupReadReceiptsCompanion.insert(
        groupId: groupId,
        memberPubKey: memberPubKey,
        lastReadMessageId: lastReadMessageId,
      ),
      onConflict: DoUpdate(
        (_) => GroupReadReceiptsCompanion(
          lastReadMessageId: Value(lastReadMessageId),
        ),
        target: [
          _db.groupReadReceipts.groupId,
          _db.groupReadReceipts.memberPubKey,
        ],
      ),
    );
  }

  Stream<List<GroupReadReceipt>> watchReadReceiptsForGroup(String groupId) {
    return (_db.select(_db.groupReadReceipts)
          ..where((row) => row.groupId.equals(groupId)))
        .watch();
  }

  Stream<int> watchUnreadCountForGroup(String groupId, String myPubKey) {
    final query = _db.customSelect(
      '''
      SELECT COUNT(*) as count FROM group_messages
      WHERE group_id = ?
        AND is_from_me = 0
        AND sender_pub_key != 'system'
        AND id > COALESCE(
          (SELECT id FROM group_messages
           WHERE message_id = (
             SELECT last_read_message_id FROM group_read_receipts
             WHERE group_id = ? AND member_pub_key = ?
           )
          ),
          0
        )
      ''',
      variables: [
        Variable.withString(groupId),
        Variable.withString(groupId),
        Variable.withString(myPubKey),
      ],
      readsFrom: {_db.groupMessages, _db.groupReadReceipts},
    );
    return query.watchSingle().map((row) => row.read<int>('count'));
  }
}

final groupRepositoryProvider = Provider<GroupRepository?>((ref) {
  final db = ref.watch(databaseProvider).asData?.value;
  return db != null ? GroupRepository(db) : null;
});

final groupsStreamProvider = StreamProvider<List<Group>>((ref) {
  final repository = ref.watch(groupRepositoryProvider);
  if (repository == null) return const Stream.empty();
  return repository.watchAllGroups();
});

final groupMembersStreamProvider =
    StreamProvider.family<List<GroupMember>, String>((ref, groupId) {
      final repository = ref.watch(groupRepositoryProvider);
      if (repository == null) return const Stream.empty();
      return repository.watchMembersForGroup(groupId);
    });

final groupMessagesStreamProvider =
    StreamProvider.family<List<GroupMessage>, String>((ref, groupId) {
      final repository = ref.watch(groupRepositoryProvider);
      if (repository == null) return const Stream.empty();
      return repository.watchMessagesForGroup(groupId);
    });

final groupReadReceiptsStreamProvider =
    StreamProvider.family<List<GroupReadReceipt>, String>((ref, groupId) {
      final repository = ref.watch(groupRepositoryProvider);
      if (repository == null) return const Stream.empty();
      return repository.watchReadReceiptsForGroup(groupId);
    });

final groupUnreadCountProvider =
    StreamProvider.family<int, (String, String)>((ref, args) {
      final (groupId, myPubKey) = args;
      final repository = ref.watch(groupRepositoryProvider);
      if (repository == null) return const Stream.empty();
      return repository.watchUnreadCountForGroup(groupId, myPubKey);
    });
