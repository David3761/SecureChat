import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/contacts/contact_request_controller.dart';
import 'package:chat/features/contacts/contacts_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactRequestsScreen extends ConsumerWidget {
  const ContactRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingInContactsProvider);
    final controller = ref.read(contactRequestControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Requests')),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (contacts) {
          if (contacts.isEmpty) {
            return const Center(child: Text('No pending requests.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final colorIndex =
                  contact.alias.hashCode.abs() % AppColors.avatarColors.length;
              final avatarColor = AppColors.avatarColors[colorIndex];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: avatarColor.withValues(alpha: 0.15),
                  child: FaIcon(
                    FontAwesomeIcons.solidUser,
                    color: avatarColor,
                    size: 16,
                  ),
                ),
                title: Text(contact.alias),
                subtitle: Text(
                  '${contact.publicKey.substring(0, 8)}...${contact.publicKey.substring(contact.publicKey.length - 8)}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.check,
                        color: AppColors.primaryBlue,
                      ),
                      onPressed: () => controller.accept(contact),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.red),
                      onPressed: () => controller.decline(contact),
                    ),
                    IconButton(
                      icon: const Icon(Icons.block, color: AppColors.grey),
                      onPressed: () => controller.block(contact),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
