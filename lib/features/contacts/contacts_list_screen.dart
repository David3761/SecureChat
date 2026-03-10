import 'package:chat/core/app_router.dart';
import 'package:chat/core/providers.dart';
import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import 'contacts_repository.dart';

class ContactsListScreen extends ConsumerWidget {
  const ContactsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsyncValue = ref.watch(contactsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contacts'),
        actions: [
          // DEBUG ONLY TODO: remove
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.storage, color: Colors.orange),
              tooltip: 'Debug DB Viewer',
              onPressed: () async {
                final db = await ref.read(databaseProvider.future);
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => DriftDbViewer(db)),
                  );
                }
              },
            ),
        ],
      ),
      body: contactsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Failed to load contacts: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (contacts) {
          if (contacts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Your vault is empty.\nTap the + button to securely add a contact via their Public Key.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  contact.alias,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  contact.publicKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmDelete(context, ref, contact),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.chat,
                    arguments: contact,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRouter.addContact);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Contact contact,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text(
          'Are you sure you want to remove ${contact.alias}? This will not delete your message history, but you will need their public key to message them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repository = await ref.read(contactsRepositoryProvider.future);
      await repository.deleteContact(contact.id);
    }
  }
}
