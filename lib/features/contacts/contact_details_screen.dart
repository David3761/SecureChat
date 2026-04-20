import 'package:chat/core/app_router.dart';
import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/database/tables.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/core/widgets/skeleton_bone.dart';
import 'package:chat/core/widgets/skeletonizer.dart';
import 'package:chat/features/contacts/contacts_repository.dart';
import 'package:chat/features/disappearing_messages/disappearing_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactDetailsScreen extends ConsumerWidget {
  final Contact contact;

  const ContactDetailsScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactStreamProvider(contact.id));

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.angleLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Contact info'),
        backgroundColor: AppColors.secondaryBackground,
      ),
      body: contactAsync.when(
        loading: () => Skeletonizer(
          child: ListView(
            children: [
              const SizedBox(height: 24),
              const Center(
                child: SkeletonBone(
                  width: 88,
                  height: 88,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 12),
              const Center(child: SkeletonBone(width: 140, height: 20)),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 6),
                child: SkeletonBone(width: 80, height: 11),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SkeletonBone(height: 56),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 6),
                child: SkeletonBone(width: 140, height: 11),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: List.generate(
                    4,
                    (i) => Column(
                      children: [
                        const ListTile(
                          title: SkeletonBone(width: 100, height: 14),
                        ),
                        if (i < 3) const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (contact) => ListView(
          children: [
            const SizedBox(height: 24),
            _buildAvatar(context, contact),
            const SizedBox(height: 32),
            _buildSectionLabel(context, "Public key"),
            _buildSection(
              context,
              children: [
                _buildPublicKeyTile(
                  context,
                  value: contact.publicKey,
                  monospace: true,
                  trailing: IconButton(
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: const Icon(Icons.copy, size: 18),
                    ),
                    color: AppColors.onSecondaryBackground,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: contact.publicKey));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Public key copied')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionLabel(context, 'Disappearing Messages'),
            _buildSection(
              context,
              children: kDisappearingOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected =
                    contact.disappearingAfterSeconds == option.seconds;
                final isLast = index == kDisappearingOptions.length - 1;
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        option.label,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.onSecondaryBackground,
                              size: 18,
                            )
                          : null,
                      onTap: () async {
                        final repo = ref.read(contactsRepositoryProvider);
                        if (repo == null) return;
                        await repo.updateDisappearingTimer(
                          contact.id,
                          option.seconds,
                        );
                      },
                    ),
                    if (!isLast)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              children: [
                ListTile(
                  title: Text(
                    'Block Contact',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: AppColors.red,
                    ),
                  ),
                  leading: const Icon(Icons.block, color: AppColors.red),
                  onTap: () => _confirmBlock(context, ref, contact),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  title: Text(
                    'Delete Contact',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(color: AppColors.red),
                  ),
                  leading: const Icon(
                    Icons.person_remove_outlined,
                    color: AppColors.red,
                  ),
                  onTap: () => _confirmDelete(context, ref, contact),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, Contact contact) {
    final colorIndex =
        contact.alias.hashCode.abs() % AppColors.avatarColors.length;
    final avatarColor = AppColors.avatarColors[colorIndex];
    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: avatarColor.withValues(alpha: 0.15),
          child: FaIcon(
            FontAwesomeIcons.solidUser,
            color: avatarColor,
            size: 36,
          ),
        ),
        const SizedBox(height: 12),
        Text(contact.alias, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
          color: AppColors.onSecondaryBackground,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildPublicKeyTile(
    BuildContext context, {
    required String value,
    bool monospace = false,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                value,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontFamily: monospace ? 'monospace' : null,
                  fontSize: monospace ? 12 : null,
                  color: AppColors.title,
                ),
              ),
            ),
          ),
          trailing ?? SizedBox.shrink(),
        ],
      ),
    );
  }

  Future<void> _confirmBlock(
    BuildContext context,
    WidgetRef ref,
    Contact contact,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Contact?'),
        content: Text(
          'Are you sure you want to block ${contact.alias}? '
          'They will no longer be able to message you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(contactsRepositoryProvider);
      if (repo == null) throw Exception('Database not ready');
      await repo.updateContactStatus(contact.id, ContactStatus.blocked);
      if (context.mounted) Navigator.pop(context);
    }
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
          'Are you sure you want to remove ${contact.alias}? '
          'This will not delete your message history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(contactsRepositoryProvider);
      if (repo == null) throw Exception('Database not ready');
      await repo.deleteContact(contact.id);
      if (context.mounted) {
        Navigator.popUntil(
          context,
          (route) =>
              route.settings.name != AppRouter.chat &&
              route.settings.name != AppRouter.contactDetails,
        );
      }
    }
  }
}
