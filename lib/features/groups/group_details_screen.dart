import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:flutter/services.dart';

import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/core/widgets/skeleton_bone.dart';
import 'package:chat/core/widgets/skeletonizer.dart';
import 'package:chat/features/contacts/contacts_repository.dart';
import 'package:chat/features/groups/add_members_sheet.dart';
import 'package:chat/features/groups/group_controller.dart';
import 'package:chat/features/groups/group_header_delegate.dart';
import 'package:chat/features/groups/group_repository.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  Future<void> _editGroupName(String currentName) async {
    final repo = ref.read(groupRepositoryProvider);
    final groupController = ref.read(
      groupChatControllerProvider(widget.group.groupId).notifier,
    );
    if (repo == null) return;

    final nameController = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Group name'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || !mounted) return;

    final savedName = newName.isEmpty ? null : newName;
    await repo.updateGroupName(widget.group.groupId, savedName);
    await groupController.sendGroupUpdate({
      'update_type': 'rename',
      'name': savedName,
    });
  }

  void _showQrInvite(String displayName, String myPubKey) {
    final qrData = jsonEncode({
      'type': 'group_invite_link',
      'group_id': widget.group.groupId,
      'admin': myPubKey,
      'name': displayName,
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Invite to $displayName',
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this QR code to invite someone to the group.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey),
            ),
            const SizedBox(height: 24),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _addMembers(
    List<GroupMember> currentMembers,
    String displayName,
    String myPubKey,
  ) async {
    final repo = ref.read(groupRepositoryProvider);
    final groupController = ref.read(
      groupChatControllerProvider(widget.group.groupId).notifier,
    );
    if (repo == null) return;

    final contacts = ref.read(contactsStreamProvider).asData?.value ?? [];
    final currentPubKeys = currentMembers.map((m) => m.publicKey).toSet();
    final available = contacts
        .where((c) => !currentPubKeys.contains(c.publicKey))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All your contacts are already in this group.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddMembersSheet(available: available),
    );

    if (selected == null || selected.isEmpty || !mounted) return;

    final selectedContacts = available
        .where((c) => selected.contains(c.publicKey))
        .toList();

    for (final contact in selectedContacts) {
      await repo.addMember(
        groupId: widget.group.groupId,
        publicKey: contact.publicKey,
        alias: contact.alias,
        isAdmin: false,
      );
      await groupController.sendGroupUpdate({
        'update_type': 'member_added',
        'pub_key': contact.publicKey,
        'alias': contact.alias,
      });
      await repo.saveGroupMessage(
        messageId: const Uuid().v4(),
        groupId: widget.group.groupId,
        senderPubKey: 'system',
        content: '${contact.alias} was added to the group',
        isFromMe: false,
      );
    }

    final allMembers = await repo.getMembersForGroup(widget.group.groupId);
    for (final contact in selectedContacts) {
      await groupController.sendGroupInvite(
        recipientPubKey: contact.publicKey,
        groupName: displayName,
        members: allMembers,
      );
    }
  }

  void _showMemberProfile(
    GroupMember member,
    Color avatarColor,
    bool canRemove,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * (canRemove ? 0.48 : 0.38),
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisAlignment: canRemove
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8.0),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (canRemove) const SizedBox(height: 28),
            CircleAvatar(
              radius: 42,
              backgroundColor: avatarColor.withValues(alpha: 0.2),
              child: FaIcon(
                FontAwesomeIcons.solidUser,
                color: avatarColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              member.alias,
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: member.publicKey));
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Public key copied')),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.publicKey,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.copy, size: 18, color: AppColors.grey),
                    ],
                  ),
                ),
              ),
            ),
            if (canRemove) ...[
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: const Text(
                    'Remove from group',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeMember(member);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _removeMember(GroupMember member) async {
    final repo = ref.read(groupRepositoryProvider);
    final groupController = ref.read(
      groupChatControllerProvider(widget.group.groupId).notifier,
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.alias} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await groupController.sendGroupUpdate({
      'update_type': 'member_removed',
      'pub_key': member.publicKey,
      'alias': member.alias,
    });
    await repo?.removeMember(widget.group.groupId, member.publicKey);
    await repo?.saveGroupMessage(
      messageId: const Uuid().v4(),
      groupId: widget.group.groupId,
      senderPubKey: 'system',
      content: '${member.alias} was removed from the group',
      isFromMe: false,
    );
  }

  Future<void> _exitGroup(String myPubKey) async {
    final repo = ref.read(groupRepositoryProvider);
    final groupController = ref.read(
      groupChatControllerProvider(widget.group.groupId).notifier,
    );
    final myAlias =
        ref.read(keyControllerProvider).nickname ?? myPubKey.substring(0, 8);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Group?'),
        content: const Text(
          'You will no longer receive messages from this group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    if (repo == null) return;
    await groupController.sendGroupUpdate({
      'update_type': 'member_left',
      'pub_key': myPubKey,
      'alias': myAlias,
    });
    await repo.leaveGroup(widget.group.groupId, myPubKey);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(
      groupMembersStreamProvider(widget.group.groupId),
    );
    ref.watch(groupChatControllerProvider(widget.group.groupId));
    final myPubKey = ref.watch(
      keyControllerProvider.select((s) => s.publicKeyHex ?? ''),
    );
    final topPadding = MediaQuery.of(context).padding.top;

    final String displayName;
    final rawName = widget.group.name;
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

    final String memberCountStr = membersAsync.maybeWhen(
      data: (members) => '${members.length} members',
      orElse: () => '',
    );

    final isAdmin = membersAsync.maybeWhen(
      data: (members) =>
          members.any((m) => m.publicKey == myPubKey && m.isAdmin),
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: GroupHeaderDelegate(
              paddingTop: topPadding,
              displayName: displayName,
              memberCountStr: memberCountStr,
              isAdmin: isAdmin,
              onBack: () => Navigator.pop(context),
              onQr: () => _showQrInvite(displayName, myPubKey),
              onEdit: () => _editGroupName(displayName),
              backgroundColor: AppColors.secondaryBackground,
              scrolledColor: AppColors.secondaryBackground.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: membersAsync.when(
              loading: () => Skeletonizer(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 8.0,
                        ),
                        child: SkeletonBone(width: 80, height: 18),
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
                                  leading: SkeletonBone(
                                    width: 40,
                                    height: 40,
                                    shape: BoxShape.circle,
                                  ),
                                  title: SkeletonBone(width: 120, height: 14),
                                ),
                                if (i < 3)
                                  const Divider(height: 1, indent: 72),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (members) {
                final isAdminUser = members.any(
                  (m) => m.publicKey == myPubKey && m.isAdmin,
                );
                final minScrollHeight =
                    MediaQuery.of(context).size.height -
                    (kToolbarHeight + topPadding);

                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minScrollHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${members.length} member${members.length == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.search, color: AppColors.title),
                          ],
                        ),
                      ),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (isAdminUser) ...[
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.secondaryBackground,
                                  child: const Icon(
                                    Icons.add,
                                    color: AppColors.title,
                                  ),
                                ),
                                title: const Text('Add members'),
                                onTap: () =>
                                    _addMembers(members, displayName, myPubKey),
                              ),
                              const Divider(height: 1, indent: 64),
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.secondaryBackground,
                                  child: const Icon(
                                    Icons.link,
                                    color: AppColors.title,
                                  ),
                                ),
                                title: const Text('Invite via QR code'),
                                onTap: () =>
                                    _showQrInvite(displayName, myPubKey),
                              ),
                              const Divider(height: 1, indent: 64),
                            ],

                            ...members.asMap().entries.map((entry) {
                              final index = entry.key;
                              final member = entry.value;
                              final isMe = member.publicKey == myPubKey;
                              final colorIndex =
                                  member.alias.hashCode.abs() %
                                  AppColors.avatarColors.length;
                              final avatarColor =
                                  AppColors.avatarColors[colorIndex];
                              final canRemove =
                                  isAdminUser && !isMe && !member.isAdmin;

                              return Column(
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: avatarColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      child: FaIcon(
                                        FontAwesomeIcons.solidUser,
                                        color:
                                            AppColors.avatarColors[colorIndex],
                                        size: 16,
                                      ),
                                    ),
                                    title: Text(isMe ? 'You' : member.alias),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        member.isAdmin
                                            ? const Text(
                                                'Admin',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.grey,
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                        const SizedBox(width: 8.0),
                                        SvgPicture.asset(
                                          'assets/right_arrow.svg',
                                          height: 20,
                                          width: 20,
                                          colorFilter: ColorFilter.mode(
                                            AppColors.grey,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _showMemberProfile(
                                      member,
                                      avatarColor,
                                      canRemove,
                                    ),
                                  ),
                                  if (index < members.length - 1)
                                    const Divider(height: 1, indent: 64),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: const Text(
                            'Exit group',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                          onTap: () => _exitGroup(myPubKey),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: Text(
                          'Created by you.\nCreated 11 Apr 2020.',
                          style: TextStyle(color: AppColors.grey, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
