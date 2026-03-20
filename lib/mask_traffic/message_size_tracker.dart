import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageSizeTracker {
  final List<int> _observedSizes = [];
  final Random _random = Random.secure();
  static const int _maxSamples = 100;

  void record(int size) {
    _observedSizes.add(size);
    if (_observedSizes.length > _maxSamples) {
      _observedSizes.removeAt(0);
    }
  }

  int realisticSize() {
    if (_observedSizes.length < 10) {
      return _fallbackSize();
    }

    final base = _observedSizes[_random.nextInt(_observedSizes.length)];
    final noise = (base * 0.15).round();
    final result = base + _random.nextInt(noise * 2 + 1) - noise;
    return result.clamp(35, 500);
  }

  int _fallbackSize() {
    final roll = _random.nextDouble();
    if (roll < 0.50) return 35 + _random.nextInt(25);
    if (roll < 0.80) return 60 + _random.nextInt(40);
    return 100 + _random.nextInt(80);
  }
}

final messageSizeTrackerProvider = Provider<MessageSizeTracker>((ref) {
  return MessageSizeTracker();
});
