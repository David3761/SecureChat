import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'contacts_repository.dart';

class AddContactState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  AddContactState({this.isLoading = false, this.error, this.isSuccess = false});
}

class AddContactController extends Notifier<AddContactState> {
  @override
  AddContactState build() => AddContactState();

  Future<void> saveContact(String alias, String publicKey) async {
    if (alias.trim().isEmpty) {
      state = AddContactState(error: 'Alias cannot be empty.');
      return;
    }

    final cleanKey = publicKey.trim().replaceAll(' ', '').toLowerCase();
    if (cleanKey.length != 64) {
      state = AddContactState(
        error: 'Invalid Public Key. Must be 64 hex characters.',
      );
      return;
    }

    state = AddContactState(isLoading: true);

    try {
      final repository = await ref.read(contactsRepositoryProvider.future);
      await repository.addContact(alias: alias.trim(), publicKey: cleanKey);

      state = AddContactState(isSuccess: true);
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        state = AddContactState(error: 'You have already added this contact.');
      } else {
        state = AddContactState(error: 'Failed to save contact: $e');
      }
    }
  }
}

final addContactControllerProvider =
    NotifierProvider<AddContactController, AddContactState>(
      () => AddContactController(),
      isAutoDispose: true,
    );
