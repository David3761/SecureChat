import 'dart:convert';

import 'package:sodium_libs/sodium_libs.dart';
import 'package:flutter/foundation.dart';

class CryptoService {
  late Sodium _sodium;

  Future<void> init() async {
    _sodium = await SodiumInit.init();
  }

  KeyPair generateNewKeyPair() {
    return _sodium.crypto.box.keyPair();
  }

  //Should only be called ONCE (on user login).
  SecureKey createSecureKeyFromHex(String hexPrivateKey) {
    Uint8List? secretKeyBytes;
    try {
      secretKeyBytes = _hexDecode(hexPrivateKey);
      return SecureKey.fromList(_sodium, secretKeyBytes);
    } finally {
      secretKeyBytes?.fillRange(0, secretKeyBytes.length, 0);
    }
  }

  KeyPair importPrivateKey(SecureKey secureSecretKey) {
    return _sodium.crypto.box.seedKeyPair(secureSecretKey);
  }

  Uint8List _hexDecode(String hexStr) {
    hexStr = hexStr.replaceAll(' ', '').toLowerCase();
    final result = Uint8List(hexStr.length ~/ 2);
    for (int i = 0; i < hexStr.length; i += 2) {
      final hexPart = hexStr.substring(i, i + 2);
      result[i ~/ 2] = int.parse(hexPart, radix: 16);
    }
    return result;
  }

  String hexEncode(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  String encryptMessage({
    required String plainText,
    required SecureKey mySecretKey,
    required String theirPublicKeyHex,
  }) {
    Uint8List? messageBytes;

    try {
      final theirPublicKey = _hexDecode(theirPublicKeyHex);

      messageBytes = Uint8List.fromList(utf8.encode(plainText));

      final nonce = _sodium.randombytes.buf(_sodium.crypto.box.nonceBytes);

      final cipherText = _sodium.crypto.box.easy(
        message: messageBytes,
        nonce: nonce,
        publicKey: theirPublicKey,
        secretKey: mySecretKey,
      );

      final encryptedBlob = Uint8List.fromList([...nonce, ...cipherText]);

      return base64Encode(encryptedBlob);
    } finally {
      messageBytes?.fillRange(0, messageBytes.length, 0);
    }
  }

  String decryptMessage({
    required String encryptedBase64,
    required SecureKey mySecretKey,
    required String theirPublicKeyHex,
  }) {
    Uint8List? decryptedBytes;

    try {
      final blob = base64Decode(encryptedBase64);
      final theirPublicKey = _hexDecode(theirPublicKeyHex);
      final nonceBytes = _sodium.crypto.box.nonceBytes;

      if (blob.length < nonceBytes) {
        throw Exception(
          'Encrypted payload is too short to contain a valid nonce.',
        );
      }

      final nonce = blob.sublist(0, nonceBytes);
      final cipherText = blob.sublist(nonceBytes);

      decryptedBytes = _sodium.crypto.box.openEasy(
        cipherText: cipherText,
        nonce: nonce,
        publicKey: theirPublicKey,
        secretKey: mySecretKey,
      );

      return utf8.decode(decryptedBytes);
    } catch (e) {
      throw Exception(
        'Decryption failed. The message may have been tampered with or keys do not match. Error: $e',
      );
    } finally {
      decryptedBytes?.fillRange(0, decryptedBytes.length, 0);
    }
  }
}
