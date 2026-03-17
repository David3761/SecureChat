import 'dart:async';
import 'package:chat/features/chat/chat_repository.dart';
import 'package:chat/features/contacts/contacts_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DisappearingMessagesService {
  Timer? _timer;
  final Ref _ref;

  DisappearingMessagesService(this._ref);

  Future<void> start() async {
    await _purge();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _purge());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _purge() async {
    try {
      final contactsRepo = await _ref.read(contactsRepositoryProvider.future);
      final messagesRepo = await _ref.read(chatRepositoryProvider.future);

      final contacts = await contactsRepo.getContactsWithDisappearing();

      for (final contact in contacts) {
        final seconds = contact.disappearingAfterSeconds;
        if (seconds == null) continue;

        final cutoff = DateTime.now().subtract(Duration(seconds: seconds));
        await messagesRepo.deleteMessagesOlderThan(contact.id, cutoff);
        debugPrint(
          'Purged messages older than ${Duration(seconds: seconds)} for ${contact.alias}',
        );
      }
    } catch (e) {
      debugPrint('Disappearing messages purge failed: $e');
    }
  }
}

final disappearingMessagesServiceProvider =
    Provider<DisappearingMessagesService>((ref) {
      final service = DisappearingMessagesService(ref);
      ref.onDispose(() => service.stop());
      return service;
    });
