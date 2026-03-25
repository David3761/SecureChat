import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/groups/group_repository.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GroupDetailsScreen extends ConsumerWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersStreamProvider(group.groupId));
    final myPubKey = ref.watch(
      keyControllerProvider.select((s) => s.publicKeyHex ?? ''),
    );

    final String displayName;
    final rawName = group.name;
    if (rawName != null && rawName.isNotEmpty) {
      displayName = rawName;
    } else {
      displayName = membersAsync.maybeWhen(
        data: (members) {
          final names = members
              .where((m) => m.publicKey != myPubKey)
              .map((m) => m.alias)
              .join(', ');
          return names.isNotEmpty ? names : 'Group';
        },
        orElse: () => 'Group',
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Group Info')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) {
          final isAdmin = members.any(
            (m) => m.publicKey == myPubKey && m.isAdmin,
          );

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryBlue.withValues(
                        alpha: 0.15,
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.userGroup,
                        size: 32,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${members.length} members',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Members',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge!.copyWith(color: AppColors.grey),
                ),
              ),

              ...members.map((member) {
                final isMe = member.publicKey == myPubKey;
                final colorIndex =
                    member.alias.hashCode.abs() % AppColors.avatarColors.length;
                final avatarColor = AppColors.avatarColors[colorIndex];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: avatarColor.withValues(alpha: 0.2),
                    child: Text(
                      member.alias[0].toUpperCase(),
                      style: TextStyle(color: avatarColor),
                    ),
                  ),
                  title: Text(isMe ? '${member.alias} (You)' : member.alias),
                  trailing: member.isAdmin
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                );
              }),

              if (isAdmin) ...[
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.secondaryBackground,
                    child: FaIcon(
                      FontAwesomeIcons.userPlus,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  title: const Text(
                    'Add member',
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                  onTap: () {
                    // TODO: implement add member (and admin permissions)
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
