import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sodium_libs/sodium_libs.dart';
import '../../core/providers.dart';

//The private key is sometimes stored as a simple string in RAM and I can't do anything about it
//What i can do is make sure it exists for the shortest amount of time possible by removing all references to it and let the gc sweep it
//Also, storing it in state as SecureKey seems the most reasonable approach
//I can't read it from secure storage every time i need it becase it would mean
//having it stored as plain String in RAM every time i send a message
//I prefer one SecureKey ranther than 50 String keys in RAM
//If there is any safer way to do this, please let me know
class KeyState {
  final bool isLoading;
  final String? errorMessage;
  final bool isKeySetupComplete;
  final SecureKey? activeSecretKey;
  final String? publicKeyHex;

  KeyState({
    this.isLoading = true,
    this.errorMessage,
    this.isKeySetupComplete = false,
    this.activeSecretKey,
    this.publicKeyHex,
  });
}

class KeyController extends Notifier<KeyState> {
  @override
  KeyState build() {
    _checkExistingKeys();

    ref.onDispose(() {
      state.activeSecretKey?.dispose();
    });

    return KeyState(isLoading: true);
  }

  Future<void> _checkExistingKeys() async {
    state = KeyState(isLoading: true);

    try {
      final storage = ref.read(secureStorageProvider);
      final lastActive = await storage.getLastActiveAccount();

      if (lastActive != null && lastActive.isNotEmpty) {
        await login(lastActive);
      } else {
        state = KeyState(isKeySetupComplete: false, isLoading: false);
      }
    } catch (e) {
      state = KeyState(
        isKeySetupComplete: false,
        isLoading: false,
        errorMessage: 'Failed to log in: $e',
      );
    }
  }

  Future<void> login(String publicKeyHex) async {
    state = KeyState(isLoading: true);

    try {
      final crypto = ref.read(cryptoServiceProvider);
      final storage = ref.read(secureStorageProvider);

      final privateKey = await storage.getPrivateKey(publicKeyHex);

      if (privateKey != null && privateKey.isNotEmpty) {
        final SecureKey secureKey = crypto.createSecureKeyFromHex(privateKey);
        await storage.setLastActiveAccount(publicKeyHex);

        state = KeyState(
          isKeySetupComplete: true,
          isLoading: false,
          activeSecretKey: secureKey,
          publicKeyHex: publicKeyHex,
        );
      } else {
        throw Exception("Private key not found for this account.");
      }
    } catch (e) {
      state = KeyState(
        isKeySetupComplete: false,
        isLoading: false,
        errorMessage: 'Login failed: $e',
      );
    }
  }

  Future<void> generateAndSaveKey() async {
    state = KeyState(isLoading: true);
    KeyPair? keyPair;

    try {
      final crypto = ref.read(cryptoServiceProvider);
      final storage = ref.read(secureStorageProvider);

      keyPair = crypto.generateNewKeyPair();
      final pubKeyHex = crypto.hexEncode(keyPair.publicKey);

      String privKeyHex = '';
      keyPair.secretKey.runUnlockedSync((keyBytes) {
        privKeyHex = crypto.hexEncode(keyBytes);
      });

      await storage.saveKeyPair(publicKey: pubKeyHex, privateKey: privKeyHex);
      await storage.setLastActiveAccount(pubKeyHex);

      state = KeyState(
        isKeySetupComplete: true,
        isLoading: false,
        activeSecretKey: keyPair.secretKey,
        publicKeyHex: pubKeyHex,
      );
    } catch (e) {
      //if an error occurs between creating the key and storing in state
      keyPair?.secretKey.dispose();

      state = KeyState(
        errorMessage: 'Failed to generate key: $e',
        isLoading: false,
      );
    }
  }

  Future<void> importAndSaveKey(String hexPrivateKey) async {
    state = KeyState(isLoading: true);
    SecureKey? seedKey;
    KeyPair? derivedKeyPair;

    try {
      final crypto = ref.read(cryptoServiceProvider);
      final storage = ref.read(secureStorageProvider);

      seedKey = crypto.createSecureKeyFromHex(hexPrivateKey);
      derivedKeyPair = crypto.importPrivateKey(seedKey);
      final pubKeyHex = crypto.hexEncode(derivedKeyPair.publicKey);

      await storage.saveKeyPair(
        publicKey: pubKeyHex,
        privateKey: hexPrivateKey,
      );
      await storage.setLastActiveAccount(pubKeyHex);

      state = KeyState(
        isKeySetupComplete: true,
        isLoading: false,
        activeSecretKey: seedKey,
        publicKeyHex: pubKeyHex,
      );
    } catch (e) {
      seedKey?.dispose();

      state = KeyState(errorMessage: 'Invalid private key.', isLoading: false);
    } finally {
      derivedKeyPair?.secretKey.dispose();
    }
  }

  Future<void> logout() async {
    state.activeSecretKey?.dispose();
    await ref.read(secureStorageProvider).removeLastActiveAccount();
    state = KeyState(isLoading: false, isKeySetupComplete: false);
  }

  Future<void> deleteAccount(String publicKey) async {
    state = KeyState(isLoading: true);

    try {
      await ref.read(secureStorageProvider).wipeAccountData(publicKey);

      final dbFolder = await getApplicationCacheDirectory();
      final file = File(p.join(dbFolder.path, 'secure_chat_$publicKey.sqlite'));
      if (await file.exists()) {
        await file.delete();
      }

      if (state.publicKeyHex == publicKey) {
        state.activeSecretKey?.dispose();
        state = KeyState(isLoading: false, isKeySetupComplete: false);
      } else {
        state = KeyState(
          isKeySetupComplete: true,
          isLoading: false,
          activeSecretKey: state.activeSecretKey,
          publicKeyHex: state.publicKeyHex,
        );
      }
    } catch (e) {
      state = KeyState(
        errorMessage: 'Failed to delete account: $e',
        isLoading: false,
        isKeySetupComplete: state.isKeySetupComplete,
        activeSecretKey: state.activeSecretKey,
        publicKeyHex: state.publicKeyHex,
      );
    }
  }
}

final keyControllerProvider = NotifierProvider<KeyController, KeyState>(
  KeyController.new,
);
