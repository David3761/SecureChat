import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/providers.dart';
import '../key_management/key_controller.dart';

class AppLockState {
  final bool isEnabled;
  final bool isLocked;
  final int timeoutSeconds;

  const AppLockState({
    this.isEnabled = false,
    this.isLocked = false,
    this.timeoutSeconds = 60,
  });

  AppLockState copyWith({
    bool? isEnabled,
    bool? isLocked,
    int? timeoutSeconds,
  }) => AppLockState(
    isEnabled: isEnabled ?? this.isEnabled,
    isLocked: isLocked ?? this.isLocked,
    timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
  );
}

class AppLockNotifier extends AsyncNotifier<AppLockState> {
  final LocalAuthentication _auth = LocalAuthentication();
  DateTime? _backgroundedAt;

  @override
  Future<AppLockState> build() async {
    final storage = ref.read(secureStorageProvider);
    final pubKey = ref.watch(
      keyControllerProvider.select((s) => s.publicKeyHex),
    );

    if (pubKey == null) return const AppLockState();

    final enabled = await storage.getAppLockEnabled(pubKey);
    final timeout = await storage.getAppLockTimeout(pubKey);

    if (enabled) {
      Future.delayed(const Duration(milliseconds: 500), () {
        authenticate();
      });
    }

    return AppLockState(
      isEnabled: enabled,
      isLocked: enabled,
      timeoutSeconds: timeout,
    );
  }

  Future<void> toggleEnabled() async {
    final storage = ref.read(secureStorageProvider);
    final pubKey = ref.read(keyControllerProvider).publicKeyHex;
    if (pubKey == null) return;

    final current = state.value ?? const AppLockState();
    final next = !current.isEnabled;

    if (next) {
      final canAuth =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuth) {
        debugPrint('Device does not support local authentication');
        return;
      }
    }

    await storage.setAppLockEnabled(pubKey, next);
    state = AsyncData(current.copyWith(isEnabled: next, isLocked: false));
  }

  Future<void> setTimeout(int seconds) async {
    final storage = ref.read(secureStorageProvider);
    final pubKey = ref.read(keyControllerProvider).publicKeyHex;
    if (pubKey == null) return;

    await storage.setAppLockTimeout(pubKey, seconds);
    state = AsyncData(
      (state.value ?? const AppLockState()).copyWith(timeoutSeconds: seconds),
    );
  }

  void onAppBackgrounded() {
    _backgroundedAt = DateTime.now();
  }

  void onAppResumed() {
    final current = state.value;
    if (current == null || !current.isEnabled) return;
    if (_backgroundedAt == null) return;

    final elapsed = DateTime.now().difference(_backgroundedAt!);
    if (elapsed.inSeconds >= current.timeoutSeconds) {
      _lock();
    }
    _backgroundedAt = null;
  }

  void _lock() {
    state = AsyncData(
      (state.value ?? const AppLockState()).copyWith(isLocked: true),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      authenticate();
    });
  }

  Future<void> authenticate() async {
    try {
      final canAuth =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();

      if (!canAuth) {
        state = AsyncData(
          (state.value ?? const AppLockState()).copyWith(isLocked: false),
        );
        return;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Unlock to access your messages',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        state = AsyncData(
          (state.value ?? const AppLockState()).copyWith(isLocked: false),
        );
      }
    } on LocalAuthException catch (e) {
      debugPrint('LocalAuthException: ${e.code} — ${e.description}');

      if (e.code == LocalAuthExceptionCode.noBiometricHardware) {
        state = AsyncData(
          (state.value ?? const AppLockState()).copyWith(isLocked: false),
        );
      } else if (e.code == LocalAuthExceptionCode.userCanceled ||
          e.code == LocalAuthExceptionCode.systemCanceled) {
        authenticate();
      }
    } catch (e) {
      debugPrint('Unexpected auth error: $e');
    }
  }
}

final appLockProvider = AsyncNotifierProvider<AppLockNotifier, AppLockState>(
  AppLockNotifier.new,
);
