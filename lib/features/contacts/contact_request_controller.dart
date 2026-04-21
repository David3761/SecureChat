import 'dart:async';
import 'dart:convert';

import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/database/tables.dart';
import 'package:chat/features/profile/profile_picture_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers.dart';
import '../key_management/key_controller.dart';

class ContactRequestController extends Notifier<Contact?> {
  @override
  Contact? build() => null;

  void showRequest(Contact contact) {
    state = contact;
  }

  Future<void> accept(Contact contact) async {
    final contactsRepo = ref.read(contactsRepositoryProvider);
    if (contactsRepo == null) return;

    await contactsRepo.updateContactStatus(contact.id, ContactStatus.active);

    final keyState = ref.read(keyControllerProvider);
    final cryptoService = ref.read(cryptoServiceProvider);
    final wsService = ref.read(webSocketServiceProvider);
    final storageService = ref.read(secureStorageProvider);

    if (keyState.activeSecretKey == null) return;
    final myPubKey = await storageService.getLastActiveAccount();
    if (myPubKey == null) return;

    final myNickname = keyState.nickname ?? 'User${myPubKey.substring(0, 5)}';

    final encryptedBlob = cryptoService.encryptMessage(
      plainText: jsonEncode({
        'type': 'contact_request_accepted',
        'nickname': myNickname,
      }),
      mySecretKey: keyState.activeSecretKey!,
      theirPublicKeyHex: contact.publicKey,
    );

    wsService.sendMessage(
      messageId: const Uuid().v4(),
      senderPubKey: myPubKey,
      recipientPubKey: contact.publicKey,
      encryptedBlob: encryptedBlob,
    );

    unawaited(
      ref
          .read(profilePictureControllerProvider)
          .sendMyProfilePicTo(contact.publicKey),
    );

    state = null;
  }

  Future<void> decline(Contact contact) async {
    final contactsRepo = ref.read(contactsRepositoryProvider);
    if (contactsRepo == null) return;
    await contactsRepo.deleteContact(contact.id);
    state = null;
  }

  Future<void> block(Contact contact) async {
    final contactsRepo = ref.read(contactsRepositoryProvider);
    if (contactsRepo == null) return;
    await contactsRepo.updateContactStatus(contact.id, ContactStatus.blocked);
    state = null;
  }
}

final contactRequestControllerProvider =
    NotifierProvider<ContactRequestController, Contact?>(
      ContactRequestController.new,
    );
