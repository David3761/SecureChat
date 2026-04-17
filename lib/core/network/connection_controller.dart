import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/database/tables.dart';
import 'package:chat/core/network/incoming_message_handler.dart';
import 'package:chat/features/groups/group_repository.dart';
import 'package:chat/features/tor/tor_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/key_management/key_controller.dart';
import '../providers.dart';

enum ConnectionState { disconnected, connecting, connected, error }

class ConnectionController extends Notifier<ConnectionState> {
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<void> _processingChain = Future.value();

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
        await _waitForRepository(activeKey);
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

  Future<void> _waitForRepository(String publicKey) async {
    const maxWait = Duration(seconds: 5);
    const interval = Duration(milliseconds: 100);
    final deadline = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(deadline)) {
      final repo = ref.read(contactsRepositoryProvider);
      if (repo != null) return;
      await Future.delayed(interval);
    }
  }

  void _setupConnectivityListener(String pubKey) {
    _connectivitySubscription?.cancel();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);

      if (hasConnection && state != ConnectionState.connected) {
        await _waitForRepository(pubKey);
        await _connect(pubKey);
        _setupMessageListener();
      } else if (!hasConnection) {
        state = ConnectionState.disconnected;
      }
    });
  }

  Future<void> _connect(String pubKey) async {
    final wsService = ref.read(webSocketServiceProvider);
    final torNotifier = ref.read(torProvider.notifier);

    state = ConnectionState.connecting;

    try {
      final torPort = torNotifier.isReady ? torNotifier.port : null;
      await wsService.connect(pubKey, torProxyPort: torPort);
      state = ConnectionState.connected;
      ref.read(chatRepositoryProvider)?.dropExpiredPendingMessages();
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
      (payload) {
        if (payload['type'] == 'message') {
          final groupId = payload['group_id'] as String?;
          _processingChain = _processingChain
              .then((_) {
                if (groupId != null && groupId.isNotEmpty) {
                  return _processIncomingGroupMessage(payload, groupId);
                } else {
                  return _processIncomingMessage(payload);
                }
              })
              .catchError((e) {
                debugPrint('Message processing error: $e');
              });
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
                await _waitForRepository(activeKey);
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
        'Successfully decrypted and saved incoming message from ${contact.alias}: $data',
      );
    } catch (e) {
      debugPrint(
        'Failed to process incoming message. Key mismatch or tampering detected. Error: $e',
      );
    }
  }

  Future<void> _processIncomingGroupMessage(
    Map<String, dynamic> payload,
    String groupId,
  ) async {
    final senderPubKey = payload['sender_pub_key'] as String;
    final encryptedBlob = payload['encrypted_blob'] as String;
    final messageId = payload['message_id'] as String;

    final keyState = ref.read(keyControllerProvider);
    if (keyState.activeSecretKey == null) return;
    if (senderPubKey == keyState.publicKeyHex) return;

    try {
      final groupRepo = ref.read(groupRepositoryProvider);
      if (groupRepo == null) return;

      final group = await groupRepo.getGroupById(groupId);
      if (group == null) return;

      final cryptoService = ref.read(cryptoServiceProvider);
      final decryptedPlaintext = cryptoService.decryptMessage(
        encryptedBase64: encryptedBlob,
        mySecretKey: keyState.activeSecretKey!,
        theirPublicKeyHex: senderPubKey,
      );

      final data = jsonDecode(decryptedPlaintext) as Map<String, dynamic>;

      if (data['type'] == 'group_text') {
        final sender = await groupRepo.getMember(groupId, senderPubKey);
        if (sender == null) {
          debugPrint('Ignored group_text from non-member $senderPubKey.');
          return;
        }
        await groupRepo.saveGroupMessage(
          messageId: messageId,
          groupId: groupId,
          senderPubKey: senderPubKey,
          content: data['content'] as String,
          isFromMe: false,
        );
        debugPrint('Saved incoming group message in group $groupId.');
      } else if (data['type'] == 'group_update') {
        final updateType = data['update_type'] as String?;
        switch (updateType) {
          case 'rename':
            final name = data['name'] as String?;
            await groupRepo.updateGroupName(groupId, name);
            debugPrint('Group $groupId renamed to $name.');
            break;
          case 'member_added':
            final addedAlias = data['alias'] as String;
            await groupRepo.addMember(
              groupId: groupId,
              publicKey: data['pub_key'] as String,
              alias: addedAlias,
              isAdmin: false,
            );
            await groupRepo.saveGroupMessage(
              messageId: const Uuid().v4(),
              groupId: groupId,
              senderPubKey: 'system',
              content: '$addedAlias was added to the group',
              isFromMe: false,
            );
            debugPrint('Member ${data['pub_key']} added to group $groupId.');
            break;
          case 'member_removed':
            final removedKey = data['pub_key'] as String;
            final removedAlias = data['alias'] as String? ?? '';
            final myKey = ref.read(keyControllerProvider).publicKeyHex;
            await groupRepo.removeMember(groupId, removedKey);
            await groupRepo.saveGroupMessage(
              messageId: const Uuid().v4(),
              groupId: groupId,
              senderPubKey: 'system',
              content: removedKey == myKey
                  ? 'You were removed from this group'
                  : '$removedAlias was removed from the group',
              isFromMe: false,
            );
            debugPrint('Member $removedKey removed from group $groupId.');
            break;
          case 'member_left':
            final leftKey = data['pub_key'] as String;
            final leftAlias = data['alias'] as String? ?? '';
            await groupRepo.removeMember(groupId, leftKey);
            await groupRepo.saveGroupMessage(
              messageId: const Uuid().v4(),
              groupId: groupId,
              senderPubKey: 'system',
              content: '$leftAlias has left',
              isFromMe: false,
            );
            debugPrint('Member $leftKey left group $groupId.');
            break;
          case 'read_receipt':
            final lastReadMessageId = data['last_read_message_id'] as String?;
            if (lastReadMessageId != null) {
              await groupRepo.upsertReadReceipt(
                groupId: groupId,
                memberPubKey: senderPubKey,
                lastReadMessageId: lastReadMessageId,
              );
              debugPrint('Read receipt from $senderPubKey in group $groupId.');
            }
            break;
        }
      }
    } catch (e) {
      debugPrint('Failed to process incoming group message: $e');
    }
  }
}

final connectionControllerProvider =
    NotifierProvider<ConnectionController, ConnectionState>(
      ConnectionController.new,
    );
