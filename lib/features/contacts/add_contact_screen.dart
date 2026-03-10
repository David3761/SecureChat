import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_contact_controller.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _aliasController = TextEditingController();
  final _publicKeyController = TextEditingController();

  @override
  void dispose() {
    _aliasController.dispose();
    _publicKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AddContactState>(addContactControllerProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact saved securely.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    });

    final state = ref.watch(addContactControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Secure Contact')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your contact\'s details. This information is stored securely on your device and never touches our servers.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),

            if (state.error != null) ...[
              Text(
                state.error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _aliasController,
              decoration: const InputDecoration(
                labelText: 'Alias (e.g., CoolDeveloper)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _publicKeyController,
              decoration: const InputDecoration(
                labelText: '64-Character Public Key',
                prefixIcon: Icon(Icons.key),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      ref
                          .read(addContactControllerProvider.notifier)
                          .saveContact(
                            _aliasController.text,
                            _publicKeyController.text,
                          );
                    },
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Contact'),
            ),
          ],
        ),
      ),
    );
  }
}
