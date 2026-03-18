import 'dart:async';
import 'dart:convert';

import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/database/tables.dart';
import 'package:chat/core/network/incoming_message_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/key_management/key_controller.dart';
import '../providers.dart';

enum ConnectionState { disconnected, connecting, connected, error }

class ConnectionController extends Notifier<ConnectionState> {
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  ConnectionState build() {
    final wsService = ref.read(webSocketServiceProvider);

    ref.onDispose(() {
      _messageSubscription?.cancel();
      _connectivitySubscription?.cancel();
      wsService.disconnect();
    });

    final activeKey = ref.watch(
      keyControllerProvider.select((state) => state.publicKeyHex),
    );

    if (activeKey != null) {
      Future.microtask(() async {
        await _connect(activeKey);
        _setupMessageListener();
        _setupConnectivityListener(activeKey);
      });
      return ConnectionState.connecting;
    } else {
      Future.microtask(() {
        _messageSubscription?.cancel();
        _connectivitySubscription?.cancel();
        _disconnect();
      });
      return ConnectionState.disconnected;
    }
  }

  void _setupConnectivityListener(String pubKey) {
    _connectivitySubscription?.cancel();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);

      if (hasConnection && state != ConnectionState.connected) {
        debugPrint('Network restored — reconnecting...');
        await _connect(pubKey);
        _setupMessageListener();
      } else if (!hasConnection) {
        debugPrint('Network lost');
        state = ConnectionState.disconnected;
      }
    });
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
      onError: (e) {
        debugPrint('WebSocket Stream Error; $e');
        state = ConnectionState.error;
      },
      onDone: () {
        debugPrint('WebSocket Stream Closed');

        state = ConnectionState.disconnected;

        final activeKey = ref.read(keyControllerProvider).publicKeyHex;
        if (activeKey != null) {
          Future.delayed(const Duration(seconds: 3), () {
            if (ref.read(keyControllerProvider).publicKeyHex != null) {
              Future.microtask(() async {
                await _connect(activeKey);
                _setupMessageListener();
                _setupConnectivityListener(activeKey);
              });
            }
          });
        }
      },
    );
  }

  Future<void> _processIncomingMessage(Map<String, dynamic> payload) async {
    final senderPubKey = payload['sender_pub_key'] as String;
    final encryptedBlob = payload['encrypted_blob'] as String;
    final messageId = payload['message_id'] as String;

    final keyState = ref.read(keyControllerProvider);
    if (keyState.activeSecretKey == null) return;
    if (senderPubKey == keyState.publicKeyHex) return;

    try {
      final contactsRepo = ref.read(contactsRepositoryProvider);
      if (contactsRepo == null) return;

      Contact? contact = await contactsRepo.getContactByPublicKey(senderPubKey);

      if (contact?.status == ContactStatus.blocked) return;

      if (contact == null) {
        final shortKey =
            '${senderPubKey.substring(0, 4)}...${senderPubKey.substring(senderPubKey.length - 4)}';
        final defaultSeconds = await ref
            .read(secureStorageProvider)
            .getDefaultDisappearingSeconds(keyState.publicKeyHex!);

        await contactsRepo.addContact(
          alias: 'Unknown ($shortKey)',
          publicKey: senderPubKey,
          disappearingAfterSeconds: defaultSeconds,
          status: ContactStatus.pendingIn,
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

      Map<String, dynamic> data;
      try {
        data = jsonDecode(decryptedPlaintext) as Map<String, dynamic>;
      } catch (_) {
        if (contact.status == ContactStatus.active) {
          final chatRepo = ref.read(chatRepositoryProvider);
          if (chatRepo == null) return;
          await chatRepo.saveMessage(
            messageId: messageId,
            contactId: contact.id,
            content: decryptedPlaintext,
            isFromMe: false,
          );
        }
        return;
      }

      await ref
          .read(incomingMessageHandlerProvider)
          .handle(
            messageId: messageId,
            senderPubKey: senderPubKey,
            data: data,
            contactId: contact.id,
            contact: contact,
          );

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
