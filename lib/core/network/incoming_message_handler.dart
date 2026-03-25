import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/database/tables.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/features/contacts/contact_request_controller.dart';
import 'package:chat/features/groups/group_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomingMessageHandler {
  final Ref _ref;
  IncomingMessageHandler(this._ref);

  Future<void> handle({
    required String messageId,
    required String senderPubKey,
    required Map<String, dynamic> data,
    required int contactId,
    required Contact contact,
  }) async {
    final chatRepo = _ref.read(chatRepositoryProvider);
    final contactsRepo = _ref.read(contactsRepositoryProvider);
    if (chatRepo == null || contactsRepo == null) return;

    switch (data['type']) {
      case 'text':
        if (contact.status != ContactStatus.active) return;
        await chatRepo.saveMessage(
          messageId: messageId,
          contactId: contactId,
          content: data['content'] as String,
          isFromMe: false,
        );
        break;
      case 'contact_request':
        final isQrInitiated = data['qr_initiated'] == true;

        if (contact.status == ContactStatus.pendingIn &&
            contact.isQrInitiated) {
          return;
        }

        await contactsRepo.updateQrInitiated(contact.id, isQrInitiated);

        if (isQrInitiated) {
          _ref
              .read(contactRequestControllerProvider.notifier)
              .showRequest(contact);
        }

        final nickname = data['nickname'] as String?;
        if (nickname != null) {
          await contactsRepo.updateAlias(contactId, nickname);
        }
        break;
      case 'contact_request_accepted':
        await contactsRepo.updateContactStatus(contactId, ContactStatus.active);

        final nickname = data['nickname'] as String?;
        if (nickname != null) {
          contactsRepo.updateAlias(contactId, nickname);
        }
        break;
      case 'profile_sync':
        final newAlias = data['nickname'] as String;
        if (contact.alias.startsWith('Unknown (')) {
          await contactsRepo.updateAlias(contactId, newAlias);
        }
        break;
      case 'messages_read':
        final readIds = (data['message_ids'] as List).cast<String>();
        await chatRepo.updateMessageStatus(
          readIds,
          MessageStatus.read,
          DateTime.now(),
        );
        break;
      case 'group_invite':
        debugPrint('[INVITE] received: ${data['group_id']}');

        final groupId = data['group_id'] as String?;
        if (groupId == null) break;

        final groupRepo = _ref.read(groupRepositoryProvider);
        if (groupRepo == null) break;

        final existing = await groupRepo.getGroupById(groupId);
        if (existing != null) break;

        final groupName = data['group_name'] as String?;
        final adminPubKey = data['admin_pub_key'] as String;
        final rawMembers = (data['members'] as List)
            .cast<Map<String, dynamic>>();

        await groupRepo.createGroup(groupId: groupId, name: groupName);

        for (final m in rawMembers) {
          await groupRepo.addMember(
            groupId: groupId,
            publicKey: m['pub_key'] as String,
            alias: m['alias'] as String,
            isAdmin: (m['pub_key'] as String) == adminPubKey,
          );
        }

        debugPrint('Joined group $groupId via invite.');
        break;
      default:
        debugPrint('Unknown message type: ${data['type']}');
    }
  }
}

final incomingMessageHandlerProvider = Provider<IncomingMessageHandler>((ref) {
  return IncomingMessageHandler(ref);
});
