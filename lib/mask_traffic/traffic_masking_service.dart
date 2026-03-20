import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:chat/core/network/websocket_service.dart';
import 'package:chat/mask_traffic/message_size_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrafficMaskingService {
  Timer? _timer;
  final Random _random = Random.secure();
  final Ref _ref;

  TrafficMaskingService(this._ref);

  Duration get _randomInterval => Duration(seconds: 30 + _random.nextInt(90));

  void start() {
    debugPrint("Scheduling the next dummy");
    _scheduleNext();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(_randomInterval, () {
      debugPrint("Sending dummy");
      _sendDummy();
      _scheduleNext();
    });
  }

  void _sendDummy() {
    try {
      final tracker = _ref.read(messageSizeTrackerProvider);
      final wsService = _ref.read(webSocketServiceProvider);

      if (wsService.isConnected) {
        final payloadSize = tracker.realisticSize();
        debugPrint("Dummy size: $payloadSize");
        final dummyBytes = List.generate(
          payloadSize,
          (_) => _random.nextInt(256),
        );
        wsService.sendDummy(base64Encode(dummyBytes));
      }
    } catch (e) {
      debugPrint('Dummy traffic send failed: $e');
    }
  }
}

final trafficMaskingServiceProvider = Provider<TrafficMaskingService>((ref) {
  final service = TrafficMaskingService(ref);
  ref.onDispose(() => service.stop());
  return service;
});
