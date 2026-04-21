import 'dart:convert';

import 'package:chat/core/providers.dart';
import 'package:chat/features/groups/group_repository.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:chat/features/profile/my_profile_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ProfilePictureController {
  final Ref _ref;
  ProfilePictureController(this._ref);

  Future<Uint8List?> pickAndCompress({
    ImageSource source = ImageSource.gallery,
  }) async {
    final result = await ImagePicker().pickImage(source: source);
    if (result == null) return null;
    final bytes = await result.readAsBytes();
    return FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 256,
      minHeight: 256,
      quality: 70,
      format: CompressFormat.jpeg,
    );
  }

  Future<void> updateMyProfilePicture(Uint8List? bytes) async {
    final profileRepo = _ref.read(myProfileRepositoryProvider);
    if (profileRepo == null) return;
    await profileRepo.saveProfilePicture(bytes);

    final contactsRepo = _ref.read(contactsRepositoryProvider);
    if (contactsRepo == null) return;
    final contacts = await contactsRepo.getActiveContacts();

    final keyState = _ref.read(keyControllerProvider);
    final cryptoService = _ref.read(cryptoServiceProvider);
    final wsService = _ref.read(webSocketServiceProvider);
    final storageService = _ref.read(secureStorageProvider);
    if (keyState.activeSecretKey == null) return;
    final myPubKey = await storageService.getLastActiveAccount();
    if (myPubKey == null) return;

    final payload = jsonEncode({
      'type': 'profile_pic_update',
      'pic_base64': bytes != null ? base64Encode(bytes) : null,
    });

    for (final contact in contacts) {
      try {
        final encrypted = cryptoService.encryptMessage(
          plainText: payload,
          mySecretKey: keyState.activeSecretKey!,
          theirPublicKeyHex: contact.publicKey,
        );
        wsService.sendMessage(
          messageId: const Uuid().v4(),
          senderPubKey: myPubKey,
          recipientPubKey: contact.publicKey,
          encryptedBlob: encrypted,
        );
      } catch (e) {
        debugPrint('Failed to sync profile pic to ${contact.alias}: $e');
      }
    }
  }

  Future<void> sendMyProfilePicTo(String recipientPubKey) async {
    final profileRepo = _ref.read(myProfileRepositoryProvider);
    if (profileRepo == null) return;
    final bytes = await profileRepo.getProfilePicture();
    if (bytes == null) return;

    final keyState = _ref.read(keyControllerProvider);
    final cryptoService = _ref.read(cryptoServiceProvider);
    final wsService = _ref.read(webSocketServiceProvider);
    final storageService = _ref.read(secureStorageProvider);
    if (keyState.activeSecretKey == null) return;
    final myPubKey = await storageService.getLastActiveAccount();
    if (myPubKey == null) return;

    try {
      final encrypted = cryptoService.encryptMessage(
        plainText: jsonEncode({
          'type': 'profile_pic_update',
          'pic_base64': base64Encode(bytes),
        }),
        mySecretKey: keyState.activeSecretKey!,
        theirPublicKeyHex: recipientPubKey,
      );
      wsService.sendMessage(
        messageId: const Uuid().v4(),
        senderPubKey: myPubKey,
        recipientPubKey: recipientPubKey,
        encryptedBlob: encrypted,
      );
    } catch (e) {
      debugPrint('Failed to send profile pic to $recipientPubKey: $e');
    }
  }

  Future<void> updateGroupProfilePicture(
    String groupId,
    Uint8List? bytes,
  ) async {
    final groupRepo = _ref.read(groupRepositoryProvider);
    if (groupRepo == null) return;
    await groupRepo.updateGroupProfilePicture(groupId, bytes);

    final members = await groupRepo.getMembersForGroup(groupId);
    final keyState = _ref.read(keyControllerProvider);
    final cryptoService = _ref.read(cryptoServiceProvider);
    final wsService = _ref.read(webSocketServiceProvider);
    final storageService = _ref.read(secureStorageProvider);
    if (keyState.activeSecretKey == null) return;
    final myPubKey = await storageService.getLastActiveAccount();
    if (myPubKey == null) return;

    final payload = jsonEncode({
      'type': 'group_update',
      'group_id': groupId,
      'update_type': 'profile_pic',
      'pic_base64': bytes != null ? base64Encode(bytes) : null,
    });

    final recipients = <Map<String, String>>[];
    for (final member in members) {
      if (member.publicKey == myPubKey) continue;
      try {
        final encrypted = cryptoService.encryptMessage(
          plainText: payload,
          mySecretKey: keyState.activeSecretKey!,
          theirPublicKeyHex: member.publicKey,
        );
        recipients.add({'pub_key': member.publicKey, 'encrypted_blob': encrypted});
      } catch (e) {
        debugPrint('Failed to encrypt group pic for ${member.alias}: $e');
      }
    }

    if (recipients.isNotEmpty) {
      wsService.sendGroupMessage(
        messageId: const Uuid().v4(),
        groupId: groupId,
        senderPubKey: myPubKey,
        recipients: recipients,
      );
    }
  }
}

final profilePictureControllerProvider = Provider<ProfilePictureController>(
  (ref) => ProfilePictureController(ref),
);
