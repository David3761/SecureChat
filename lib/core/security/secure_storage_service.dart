import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _privateKeyId = 'user_private_key';
  static const String _publicKeyId = 'user_public_key';
  static const String _dbEncryptionKeyId = 'db_encryption_key';

  SecureStorageService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  Future<void> saveKeyPair({
    required String publicKey,
    required String privateKey,
  }) async {
    await _storage.write(key: _publicKeyId, value: publicKey);
    await _storage.write(key: _privateKeyId, value: privateKey);
  }

  Future<String?> getPrivateKey() async {
    return await _storage.read(key: _privateKeyId);
  }

  Future<String?> getPublicKey() async {
    return await _storage.read(key: _publicKeyId);
  }

  Future<String> getOrCreateDatabaseKey() async {
    String? dbKey = await _storage.read(key: _dbEncryptionKeyId);

    if (dbKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      dbKey = base64UrlEncode(keyBytes);

      await _storage.write(key: _dbEncryptionKeyId, value: dbKey);
    }

    return dbKey;
  }

  Future<void> wipeAllData() async {
    await _storage.delete(key: _privateKeyId);
    await _storage.delete(key: _publicKeyId);
    await _storage.delete(key: _dbEncryptionKeyId);
  }
}
