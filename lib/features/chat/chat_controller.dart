import 'dart:convert';

import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/database/tables.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:chat/mask_traffic/message_size_tracker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ChatController extends AsyncNotifier<void> {
  final int contactId;

  ChatController(this.contactId);

  @override
  Future<void> build() async {}

  Future<void> sendMessage(String plainText, Contact contact) async {
    if (plainText.isEmpty) return;

    state = const AsyncValue.loading();

    try {
      final keyState = ref.read(keyControllerProvider);
      final cryptoService = ref.read(cryptoServiceProvider);
      final wsService = ref.read(webSocketServiceProvider);
      final storageService = ref.read(secureStorageProvider);
      final repository = ref.read(chatRepositoryProvider);

      if (repository == null) throw Exception('Database not ready.');
      if (keyState.activeSecretKey == null) {
        throw Exception('Private key not loaded in memory.');
      }

      final myPubKey = await storageService.getLastActiveAccount();
      if (myPubKey == null) throw Exception("Missing public key");

      final messageId = const Uuid().v4();

      final payload = jsonEncode({'type': 'text', 'content': plainText});

      final encryptedBase64Blob = cryptoService.encryptMessage(
        plainText: payload,
        mySecretKey: keyState.activeSecretKey!,
        theirPublicKeyHex: contact.publicKey,
      );

      await repository.saveMessage(
        messageId: messageId,
        contactId: contactId,
        content: plainText,
        isFromMe: true,
      );

      try {
        final size = wsService.sendMessage(
          messageId: messageId,
          senderPubKey: myPubKey,
          recipientPubKey: contact.publicKey,
          encryptedBlob: encryptedBase64Blob,
        );
        ref.read(messageSizeTrackerProvider).record(size);

        wsService.ackStream
            ?.firstWhere((id) => id == messageId)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                repository.updateMessageStatus(
                  [messageId],
                  MessageStatus.failed,
                  null,
                );
                return '';
              },
            )
            .then((id) async {
              if (id.isEmpty) return;
              await repository.updateMessageStatus(
                [id],
                MessageStatus.delivered,
                null,
              );
            });
      } catch (e) {
        await repository.updateMessageStatus(
          [messageId],
          MessageStatus.failed,
          null,
        );
        rethrow;
      }

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> retryMessage(String messageId, Contact contact) async {
    try {
      final keyState = ref.read(keyControllerProvider);
      final cryptoService = ref.read(cryptoServiceProvider);
      final wsService = ref.read(webSocketServiceProvider);
      final storageService = ref.read(secureStorageProvider);
      final repository = ref.read(chatRepositoryProvider);

      if (repository == null) throw Exception('Database not ready.');
      if (keyState.activeSecretKey == null) {
        throw Exception('Private key not loaded.');
      }
      final myPubKey = await storageService.getLastActiveAccount();
      if (myPubKey == null) throw Exception('Missing public key.');

      final message = await repository.getMessageById(messageId);
      if (message == null) throw Exception('Message not found.');

      await repository.updateMessageStatus(
        [messageId],
        MessageStatus.sending,
        null,
      );

      final encryptedBase64Blob = cryptoService.encryptMessage(
        plainText: jsonEncode({'type': 'text', 'content': message.content}),
        mySecretKey: keyState.activeSecretKey!,
        theirPublicKeyHex: contact.publicKey,
      );

      try {
        final size = wsService.sendMessage(
          messageId: messageId,
          senderPubKey: myPubKey,
          recipientPubKey: contact.publicKey,
          encryptedBlob: encryptedBase64Blob,
        );
        ref.read(messageSizeTrackerProvider).record(size);

        wsService.ackStream
            ?.firstWhere((id) => id == messageId)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                repository.updateMessageStatus(
                  [messageId],
                  MessageStatus.failed,
                  null,
                );
                return '';
              },
            )
            .then((id) async {
              if (id.isEmpty) return;
              await repository.updateMessageStatus(
                [id],
                MessageStatus.delivered,
                null,
              );
            });
      } catch (_) {
        await repository.updateMessageStatus(
          [messageId],
          MessageStatus.failed,
          null,
        );
        rethrow;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendProfileSync(Contact contact) async {
    try {
      final keyState = ref.read(keyControllerProvider);
      final cryptoService = ref.read(cryptoServiceProvider);
      final wsService = ref.read(webSocketServiceProvider);
      final storageService = ref.read(secureStorageProvider);

      if (keyState.activeSecretKey == null) {
        throw Exception("Secret key is null");
      }
      final myPubKey = await storageService.getLastActiveAccount();
      if (myPubKey == null) {
        throw Exception("Public key is null <=> User not logged in");
      }

      final myNickname = keyState.nickname ?? 'User${myPubKey.substring(0, 5)}';

      final payload = jsonEncode({
        'type': 'profile_sync',
        'nickname': myNickname,
      });

      final encryptedBase64Blob = cryptoService.encryptMessage(
        plainText: payload,
        mySecretKey: keyState.activeSecretKey!,
        theirPublicKeyHex: contact.publicKey,
      );

      final size = wsService.sendMessage(
        messageId: const Uuid().v4(),
        senderPubKey: myPubKey,
        recipientPubKey: contact.publicKey,
        encryptedBlob: encryptedBase64Blob,
      );
      ref.read(messageSizeTrackerProvider).record(size);
    } catch (e) {
      debugPrint("Profile sync failed: $e");
    }
  }

  Future<void> markAsReadAndNotify(
    Contact contact,
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) return;

    try {
      final keyState = ref.read(keyControllerProvider);
      final cryptoService = ref.read(cryptoServiceProvider);
      final wsService = ref.read(webSocketServiceProvider);
      final storageService = ref.read(secureStorageProvider);
      final repository = ref.read(chatRepositoryProvider);

      if (repository == null) throw Exception('Database not ready.');
      if (keyState.activeSecretKey == null) {
        throw Exception('Private key not loaded.');
      }
      final myPubKey = await storageService.getLastActiveAccount();
      if (myPubKey == null) throw Exception('Missing public key.');

      final payload = jsonEncode({
        'type': 'messages_read',
        'message_ids': messageIds,
      });

      final encryptedBlob = cryptoService.encryptMessage(
        plainText: payload,
        mySecretKey: keyState.activeSecretKey!,
        theirPublicKeyHex: contact.publicKey,
      );

      await repository.updateMessageStatus(
        messageIds,
        MessageStatus.read,
        DateTime.now(),
      );

      final size = wsService.sendMessage(
        messageId: const Uuid().v4(),
        senderPubKey: myPubKey,
        recipientPubKey: contact.publicKey,
        encryptedBlob: encryptedBlob,
      );
      ref.read(messageSizeTrackerProvider).record(size);
    } catch (e) {
      debugPrint("Failed to notify read status: $e");
    }
  }
}

final chatControllerProvider =
    AsyncNotifierProvider.family<ChatController, void, int>(
      ChatController.new,
      isAutoDispose: true,
    );
