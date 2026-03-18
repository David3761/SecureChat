import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/contacts/contact_request_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactRequestModal extends ConsumerWidget {
  final Contact contact;
  const ContactRequestModal({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(contactRequestControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.onSecondaryBackground.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Contact Request',
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
            child: const FaIcon(
              FontAwesomeIcons.solidUser,
              color: AppColors.primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(contact.alias, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '${contact.publicKey.substring(0, 8)}...${contact.publicKey.substring(contact.publicKey.length - 8)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await controller.accept(contact);
              },
              child: const Text('Accept'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                Navigator.pop(context);
                await controller.decline(contact);
              },
              child: const Text('Decline'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await controller.block(contact);
            },
            child: const Text('Block', style: TextStyle(color: AppColors.red)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
