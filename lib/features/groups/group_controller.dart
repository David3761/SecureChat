import 'dart:convert';

import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/database/tables.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/features/groups/group_repository.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class GroupChatController extends AsyncNotifier<void> {
  final String groupId;

  GroupChatController(this.groupId);

  @override
  Future<void> build() async {}

  Future<void> sendMessage(String plainText, List<GroupMember> members) async {
    if (plainText.isEmpty) return;

    state = const AsyncValue.loading();

    try {
      final keyState = ref.read(keyControllerProvider);
      final cryptoService = ref.read(cryptoServiceProvider);
      final wsService = ref.read(webSocketServiceProvider);
      final storageService = ref.read(secureStorageProvider);
      final groupRepo = ref.read(groupRepositoryProvider);

      if (groupRepo == null) throw Exception('Database not ready.');
      if (keyState.activeSecretKey == null) {
        throw Exception('Private key not loaded in memory.');
      }

      final myPubKey = await storageService.getLastActiveAccount();
      if (myPubKey == null) throw Exception('Missing public key.');

      final messageId = const Uuid().v4();
      final innerPayload = jsonEncode({
        'type': 'group_text',
        'group_id': groupId,
        'content': plainText,
      });

      final recipients = <Map<String, String>>[];
      for (final member in members) {
        if (member.publicKey == myPubKey) continue;
        final blob = cryptoService.encryptMessage(
          plainText: innerPayload,
          mySecretKey: keyState.activeSecretKey!,
          theirPublicKeyHex: member.publicKey,
        );
        recipients.add({'pub_key': member.publicKey, 'encrypted_blob': blob});
      }

      await groupRepo.saveGroupMessage(
        messageId: messageId,
        groupId: groupId,
        senderPubKey: myPubKey,
        content: plainText,
        isFromMe: true,
      );

      if (recipients.isEmpty) {
        await groupRepo.updateGroupMessageStatus([
          messageId,
        ], MessageStatus.delivered);
        state = const AsyncValue.data(null);
        return;
      }

      try {
        wsService.sendGroupMessage(
          messageId: messageId,
          groupId: groupId,
          senderPubKey: myPubKey,
          recipients: recipients,
        );

        wsService.ackStream
            ?.firstWhere((id) => id == messageId)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                groupRepo.updateGroupMessageStatus([
                  messageId,
                ], MessageStatus.failed);
                return '';
              },
            )
            .then((id) async {
              if (id.isEmpty) return;
              await groupRepo.updateGroupMessageStatus([
                id,
              ], MessageStatus.delivered);
            });
      } catch (e) {
        await groupRepo.updateGroupMessageStatus([
          messageId,
        ], MessageStatus.failed);
        rethrow;
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendGroupUpdate(Map<String, dynamic> updateFields) async {
    try {
      final keyState = ref.read(keyControllerProvider);
      final cryptoService = ref.read(cryptoServiceProvider);
      final wsService = ref.read(webSocketServiceProvider);
      final storageService = ref.read(secureStorageProvider);
      final groupRepo = ref.read(groupRepositoryProvider);

      if (groupRepo == null) return;
      if (keyState.activeSecretKey == null) return;

      final myPubKey = await storageService.getLastActiveAccount();
      if (myPubKey == null) return;

      final members = await groupRepo.getMembersForGroup(groupId);

      final payload = jsonEncode({
        'type': 'group_update',
        'group_id': groupId,
        ...updateFields,
      });

      final recipients = <Map<String, String>>[];
      for (final member in members) {
        if (member.publicKey == myPubKey) continue;
        final blob = cryptoService.encryptMessage(
          plainText: payload,
          mySecretKey: keyState.activeSecretKey!,
          theirPublicKeyHex: member.publicKey,
        );
        recipients.add({'pub_key': member.publicKey, 'encrypted_blob': blob});
      }

      if (recipients.isEmpty) return;

      wsService.sendGroupMessage(
        messageId: const Uuid().v4(),
        groupId: groupId,
        senderPubKey: myPubKey,
        recipients: recipients,
      );
    } catch (e) {
      debugPrint('Failed to send group update: $e');
    }
  }

  Future<void> sendReadReceipt(String lastReadMessageId) async {
    try {
      final groupRepo = ref.read(groupRepositoryProvider);
      final storageService = ref.read(secureStorageProvider);

      if (groupRepo == null) return;

      final myPubKey = await storageService.getLastActiveAccount();
      if (myPubKey == null) return;

      await groupRepo.upsertReadReceipt(
        groupId: groupId,
        memberPubKey: myPubKey,
        lastReadMessageId: lastReadMessageId,
      );

      await sendGroupUpdate({
        'update_type': 'read_receipt',
        'last_read_message_id': lastReadMessageId,
      });
    } catch (e) {
      debugPrint('Failed to send read receipt: $e');
    }
  }

  Future<void> sendGroupInvite({
    required String recipientPubKey,
    required String? groupName,
    required List<GroupMember> members,
  }) async {
    try {
      final keyState = ref.read(keyControllerProvider);
      final cryptoService = ref.read(cryptoServiceProvider);
      final wsService = ref.read(webSocketServiceProvider);
      final storageService = ref.read(secureStorageProvider);

      if (keyState.activeSecretKey == null) return;
      final myPubKey = await storageService.getLastActiveAccount();
      if (myPubKey == null) return;

      final payload = jsonEncode({
        'type': 'group_invite',
        'group_id': groupId,
        'group_name': groupName,
        'admin_pub_key': myPubKey,
        'members': members
            .map((m) => {'pub_key': m.publicKey, 'alias': m.alias})
            .toList(),
      });

      final blob = cryptoService.encryptMessage(
        plainText: payload,
        mySecretKey: keyState.activeSecretKey!,
        theirPublicKeyHex: recipientPubKey,
      );

      wsService.sendMessage(
        messageId: const Uuid().v4(),
        senderPubKey: myPubKey,
        recipientPubKey: recipientPubKey,
        encryptedBlob: blob,
      );
    } catch (e) {
      debugPrint('Failed to send group invite to $recipientPubKey: $e');
    }
  }
}

final groupChatControllerProvider =
    AsyncNotifierProvider.family<GroupChatController, void, String>(
      GroupChatController.new,
    );
