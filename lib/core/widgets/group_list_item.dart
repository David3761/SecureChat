import 'package:chat/core/app_router.dart';
import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/widgets/profile_avatar.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/groups/group_repository.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:chat/features/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GroupListItem extends ConsumerWidget {
  final Group group;
  final Function(BuildContext, WidgetRef, Group) confirmDelete;

  const GroupListItem({
    super.key,
    required this.group,
    required this.confirmDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(groupMessagesStreamProvider(group.groupId));
    final membersAsync = ref.watch(groupMembersStreamProvider(group.groupId));
    final myPubKey = ref.watch(
      keyControllerProvider.select((s) => s.publicKeyHex ?? ''),
    );
    final unreadCountAsync = ref.watch(
      groupUnreadCountProvider((group.groupId, myPubKey)),
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

    final colorIndex =
        displayName.hashCode.abs() % AppColors.avatarColors.length;
    final avatarColor = AppColors.avatarColors[colorIndex];

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRouter.groupChat, arguments: group),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Slidable(
            key: ValueKey(group.groupId),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.4,
              children: [
                CustomSlidableAction(
                  onPressed: (context) => confirmDelete(context, ref, group),
                  backgroundColor: AppColors.red,
                  foregroundColor: AppColors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/trash_icon.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Leave',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.only(top: 16),
              width: double.infinity,
              child: Row(
                children: [
                  ProfileAvatar(
                    imageData: group.profilePicture,
                    radius: 32,
                    backgroundColor: avatarColor.withValues(alpha: 0.2),
                    iconColor: avatarColor,
                    fallbackIcon: FontAwesomeIcons.userGroup,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              messagesAsync.maybeWhen(
                                data: (messages) {
                                  if (messages.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      formatDateTimeContact(
                                        messages.first.timestamp,
                                      ),
                                    ),
                                  );
                                },
                                orElse: () => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          messagesAsync.maybeWhen(
                            data: (messages) {
                              if (messages.isEmpty) {
                                return Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                );
                              }
                              final last = messages.first;
                              final unreadCount = unreadCountAsync.maybeWhen(
                                data: (c) => c,
                                orElse: () => 0,
                              );

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      last.isFromMe
                                          ? last.content
                                          : last.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          unreadCount > 9
                                              ? '+9'
                                              : unreadCount.toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall!
                                              .copyWith(color: AppColors.white),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(indent: 80),
        ],
      ),
    );
  }
}
