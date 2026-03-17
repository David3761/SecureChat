import 'dart:async';
import 'dart:convert';

import 'package:chat/core/database/tables.dart';
import 'package:chat/features/chat/chat_repository.dart';
import 'package:chat/features/contacts/contacts_repository.dart';
import 'package:chat/features/disappearing_messages/disappearing_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/key_management/key_controller.dart';
import '../providers.dart';

enum ConnectionState { disconnected, connecting, connected, error }

class ConnectionController extends Notifier<ConnectionState> {
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  @override
  ConnectionState build() {
    final wsService = ref.read(webSocketServiceProvider);

    ref.onDispose(() {
      _messageSubscription?.cancel();
      wsService.disconnect();
    });

    final activeKey = ref.watch(
      keyControllerProvider.select((state) => state.publicKeyHex),
    );

    if (activeKey != null) {
      Future.microtask(() async {
        await _connect(activeKey);
        _setupMessageListener();
        ref.read(disappearingMessagesServiceProvider).start();
      });
      return ConnectionState.connecting;
    } else {
      Future.microtask(() {
        _messageSubscription?.cancel();
        _disconnect();
      });
      return ConnectionState.disconnected;
    }
  }

  Future<void> _connect(String pubKey) async {
    final wsService = ref.read(webSocketServiceProvider);

    state = ConnectionState.connecting;

    try {
      await wsService.connect(pubKey);
      debugPrint("Successfully conected the frontend");
      state = ConnectionState.connected;
    } catch (e) {
      state = ConnectionState.error;
    }
  }

  void _disconnect() {
    final currentKey = ref.read(keyControllerProvider).publicKeyHex;
    final wsService = ref.read(webSocketServiceProvider);

    if (currentKey != null) {
      wsService.disconnectGracefully(currentKey);
    } else {
      wsService.disconnect();
    }

    state = ConnectionState.disconnected;
  }

  void _setupMessageListener() {
    final wsService = ref.read(webSocketServiceProvider);

    _messageSubscription?.cancel();

    _messageSubscription = wsService.incomingMessages?.listen(
      (payload) async {
        if (payload['type'] == 'message') {
          await _processIncomingMessage(payload);
        }
      },
      onError: (e) => debugPrint('WebSocket Stream Error; $e'),
      onDone: () => debugPrint('WebSocket Stream Closed'),
    );
  }

  Future<void> _processIncomingMessage(Map<String, dynamic> payload) async {
    final senderPubKey = payload['sender_pub_key'] as String;
    final encryptedBlob = payload['encrypted_blob'] as String;
    final messageId = payload['message_id'] as String;

    final keyState = ref.read(keyControllerProvider);
    if (keyState.activeSecretKey == null) return;

    if (senderPubKey == keyState.publicKeyHex) {
      debugPrint('Dropping echoed package from myself.');
      return;
    }

    try {
      final contactsRepo = await ref.read(contactsRepositoryProvider.future);
      var contact = await contactsRepo.getContactByPublicKey(senderPubKey);

      //TODO: special section for stranger messaging me
      if (contact == null) {
        final shortKey =
            '${senderPubKey.substring(0, 4)}...${senderPubKey.substring(senderPubKey.length - 4)}';
        await contactsRepo.addContact(
          alias: 'Unknown ($shortKey)',
          publicKey: senderPubKey,
        );
        contact = await contactsRepo.getContactByPublicKey(senderPubKey);
      }

      if (contact == null) throw Exception("Failed to resolve contact.");

      final cryptoService = ref.read(cryptoServiceProvider);
      final decryptedPlaintext = cryptoService.decryptMessage(
        encryptedBase64: encryptedBlob,
        mySecretKey: keyState.activeSecretKey!,
        theirPublicKeyHex: senderPubKey,
      );

      try {
        final Map<String, dynamic> data = jsonDecode(decryptedPlaintext);

        if (data['type'] == 'text') {
          final chatRepo = await ref.read(chatRepositoryProvider.future);
          await chatRepo.saveMessage(
            messageId: messageId,
            contactId: contact.id,
            content: data['content'],
            isFromMe: false,
          );
        } else if (data['type'] == 'profile_sync') {
          //TODO: after profile sync, I appear directly on his list screen. there needs to be an "accept request mechanism"
          //TODO: separate concerns here
          final newAlias = data['nickname'] as String;
          await contactsRepo.updateAlias(contact.id, newAlias);
        } else if (data['type'] == 'messages_read') {
          final List<dynamic> rawIds = data['message_ids'];
          final List<String> readMessageIds = rawIds.cast<String>();

          final chatRepo = await ref.read(chatRepositoryProvider.future);

          await chatRepo.updateMessageStatus(
            readMessageIds,
            MessageStatus.read,
            null,
          );

          debugPrint(
            'The other user read ${readMessageIds.length} of our messages.',
          );
        }
      } catch (formatException) {
        final chatRepo = await ref.read(chatRepositoryProvider.future);
        await chatRepo.saveMessage(
          messageId: messageId,
          contactId: contact.id,
          content: decryptedPlaintext,
          isFromMe: false,
        );
      }

      debugPrint(
        'Successfully decrypted and saved incoming message from ${contact.alias}.',
      );
    } catch (e) {
      debugPrint(
        'Failed to process incoming message. Key mismatch or tampering detected. Error: $e',
      );
    }
  }
}

final connectionControllerProvider =
    NotifierProvider<ConnectionController, ConnectionState>(
      ConnectionController.new,
    );
