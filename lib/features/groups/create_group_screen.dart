import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/contacts/contacts_repository.dart';
import 'package:chat/features/groups/group_controller.dart';
import 'package:chat/features/groups/group_repository.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedPubKeys = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _buildDefaultName(List<Contact> contacts) {
    final selected = contacts
        .where((c) => _selectedPubKeys.contains(c.publicKey))
        .map((c) => c.alias)
        .toList();
    final myNickname = ref.read(keyControllerProvider).nickname ?? 'Me';
    selected.insert(0, myNickname);
    return selected.join(', ');
  }

  Future<void> _create(List<Contact> allContacts) async {
    if (_selectedPubKeys.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      final keyState = ref.read(keyControllerProvider);
      final storageService = ref.read(secureStorageProvider);
      final groupRepo = ref.read(groupRepositoryProvider);

      if (groupRepo == null) throw Exception('Database not ready.');

      final myPubKey = await storageService.getLastActiveAccount();
      if (myPubKey == null) throw Exception('Missing public key.');

      final groupId = const Uuid().v4();
      final rawName = _nameController.text.trim();
      final groupName = rawName.isNotEmpty ? rawName : null;

      await groupRepo.createGroup(groupId: groupId, name: groupName);

      final myAlias = keyState.nickname ?? 'User${myPubKey.substring(0, 5)}';
      await groupRepo.addMember(
        groupId: groupId,
        publicKey: myPubKey,
        alias: myAlias,
        isAdmin: true,
      );

      final selectedContacts = allContacts
          .where((c) => _selectedPubKeys.contains(c.publicKey))
          .toList();

      for (final contact in selectedContacts) {
        await groupRepo.addMember(
          groupId: groupId,
          publicKey: contact.publicKey,
          alias: contact.alias,
          isAdmin: false,
        );
      }

      final allMembers = await groupRepo.getMembersForGroup(groupId);
      final controller = ref.read(
        groupChatControllerProvider(groupId).notifier,
      );

      for (final contact in selectedContacts) {
        await controller.sendGroupInvite(
          recipientPubKey: contact.publicKey,
          groupName: groupName ?? _buildDefaultName(allContacts),
          members: allMembers,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        actions: [
          contactsAsync.maybeWhen(
            data: (contacts) => TextButton(
              onPressed: _selectedPubKeys.isEmpty || _isCreating
                  ? null
                  : () => _create(contacts),
              child: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Group name (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Add members',
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(color: AppColors.grey),
            ),
          ),
          Expanded(
            child: contactsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (contacts) {
                if (contacts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No contacts yet.\nAdd contacts first to create a group.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final selected = _selectedPubKeys.contains(
                      contact.publicKey,
                    );
                    final colorIndex =
                        contact.alias.hashCode.abs() %
                        AppColors.avatarColors.length;
                    final avatarColor = AppColors.avatarColors[colorIndex];

                    return CheckboxListTile(
                      value: selected,
                      onChanged: (_) => setState(() {
                        if (selected) {
                          _selectedPubKeys.remove(contact.publicKey);
                        } else {
                          _selectedPubKeys.add(contact.publicKey);
                        }
                      }),
                      title: Text(contact.alias),
                      secondary: CircleAvatar(
                        backgroundColor: avatarColor.withValues(alpha: 0.2),
                        child: Text(
                          contact.alias[0].toUpperCase(),
                          style: TextStyle(color: avatarColor),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
