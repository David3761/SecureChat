import 'package:chat/core/providers.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:chat/mask_traffic/traffic_masking_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final maskTrafficProvider = AsyncNotifierProvider<MaskTrafficNotifier, bool>(
  MaskTrafficNotifier.new,
);

class MaskTrafficNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final storage = ref.read(secureStorageProvider);
    final pubKey = ref.watch(
      keyControllerProvider.select((s) => s.publicKeyHex),
    );
    if (pubKey == null) return false;
    return await storage.getMaskTrafficEnabled(pubKey);
  }

  Future<void> toggle() async {
    final storage = ref.read(secureStorageProvider);
    final pubKey = ref.read(keyControllerProvider).publicKeyHex;
    if (pubKey == null) return;

    final current = state.value ?? false;
    final next = !current;

    await storage.setMaskTrafficEnabled(pubKey, next);
    state = AsyncData(next);

    if (next) {
      ref.read(trafficMaskingServiceProvider).start();
      debugPrint("Traffic masking started");
    } else {
      ref.read(trafficMaskingServiceProvider).stop();
      debugPrint("Traffic masking stopped");
    }
  }
}
