import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/features/chat/chat_repository.dart';
import 'package:chat/features/key_management/key_controller.dart';
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
      final repository = await ref.read(chatRepositoryProvider.future);

      if (keyState.activeSecretKey == null) {
        throw Exception('Private key not loaded in memory.');
      }

      final myPubKey = await storageService.getLastActiveAccount();
      if (myPubKey == null) throw Exception("Missing public key");

      final messageId = const Uuid().v4();

      final encryptedBase64Blob = cryptoService.encryptMessage(
        plainText: plainText,
        mySecretKey: keyState.activeSecretKey!,
        theirPublicKeyHex: contact.publicKey,
      );

      await repository.saveMessage(
        messageId: messageId,
        contactId: contactId,
        content: plainText,
        isFromMe: true,
      );

      wsService.sendMessage(
        messageId: messageId,
        senderPubKey: myPubKey,
        recipientPubKey: contact.publicKey,
        encryptedBlob: encryptedBase64Blob,
      );

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final chatControllerProvider =
    AsyncNotifierProvider.family<ChatController, void, int>(
      ChatController.new,
      isAutoDispose: true,
    );
