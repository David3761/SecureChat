import 'package:chat/core/database/tables.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/features/contacts/contacts_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockedContactsScreen extends ConsumerWidget {
  const BlockedContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedContactsProvider);
    final contactsRepo = ref.read(contactsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Contacts')),
      body: blockedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (contacts) {
          if (contacts.isEmpty) {
            return const Center(child: Text('No blocked contacts.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                title: Text(contact.alias),
                subtitle: Text(
                  '${contact.publicKey.substring(0, 8)}...${contact.publicKey.substring(contact.publicKey.length - 8)}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await contactsRepo?.updateContactStatus(
                      contact.id,
                      ContactStatus.active,
                    );
                  },
                  child: const Text('Unblock'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
