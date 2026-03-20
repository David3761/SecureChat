import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _knownAccountsKey = 'known_accounts';
  static const String _lastActiveAccountKey = 'last_active_account';

  SecureStorageService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  String _privateKeyId(String publicKey) => '${publicKey}_private_key';
  String _dbKeyId(String publicKey) => '${publicKey}_db_encryption_key';
  String _nicknameId(String publicKey) => '${publicKey}_nickname';
  String _defaultDisappearingId(String publicKey) =>
      '${publicKey}_default_disappearing_seconds';

  //TODO add the nickname to the account data
  Future<List<String>> getKnownAccounts() async {
    final str = await _storage.read(key: _knownAccountsKey);
    if (str == null) return [];
    return List<String>.from(jsonDecode(str));
  }

  Future<String?> getLastActiveAccount() async {
    return await _storage.read(key: _lastActiveAccountKey);
  }

  Future<void> setLastActiveAccount(String publicKey) async {
    await _storage.write(key: _lastActiveAccountKey, value: publicKey);
  }

  Future<void> removeLastActiveAccount() async {
    await _storage.delete(key: _lastActiveAccountKey);
  }

  Future<void> saveKeyPair({
    required String publicKey,
    required String privateKey,
  }) async {
    await _storage.write(key: _privateKeyId(publicKey), value: privateKey);

    final accounts = await getKnownAccounts();
    if (!accounts.contains(publicKey)) {
      accounts.add(publicKey);
      await _storage.write(key: _knownAccountsKey, value: jsonEncode(accounts));
    }
  }

  Future<String?> getPrivateKey(String publicKey) async {
    return await _storage.read(key: _privateKeyId(publicKey));
  }

  Future<String?> getNickname(String publicKey) async {
    return await _storage.read(key: _nicknameId(publicKey));
  }

  Future<void> saveNickname(String publicKey, String nickname) async {
    await _storage.write(key: _nicknameId(publicKey), value: nickname);
  }

  Future<String> getOrCreateDatabaseKey(String publicKey) async {
    final targetKey = _dbKeyId(publicKey);
    String? dbKey = await _storage.read(key: targetKey);

    if (dbKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      dbKey = base64UrlEncode(keyBytes);

      await _storage.write(key: targetKey, value: dbKey);
    }

    return dbKey;
  }

  Future<void> saveDefaultDisappearingSeconds(
    String publicKey,
    int? seconds,
  ) async {
    final key = _defaultDisappearingId(publicKey);
    if (seconds == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: seconds.toString());
    }
  }

  Future<int?> getDefaultDisappearingSeconds(String publicKey) async {
    final value = await _storage.read(key: _defaultDisappearingId(publicKey));
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<void> setMaskTrafficEnabled(String publicKey, bool enabled) async {
    await _storage.write(
      key: '${publicKey}_mask_traffic',
      value: enabled.toString(),
    );
  }

  Future<bool> getMaskTrafficEnabled(String publicKey) async {
    final value = await _storage.read(key: '${publicKey}_mask_traffic');
    return value == 'true';
  }

  Future<void> wipeAccountData(String publicKey) async {
    await _storage.delete(key: _privateKeyId(publicKey));
    await _storage.delete(key: _dbKeyId(publicKey));
    await _storage.delete(key: _nicknameId(publicKey));
    await _storage.delete(key: _defaultDisappearingId(publicKey));

    final accounts = await getKnownAccounts();
    accounts.remove(publicKey);
    await _storage.write(key: _knownAccountsKey, value: jsonEncode(accounts));

    final lastActive = await getLastActiveAccount();
    if (lastActive == publicKey) await removeLastActiveAccount();
  }

  Future<void> wipeAllData() async {
    await _storage.deleteAll();
  }
}
