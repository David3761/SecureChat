import 'package:chat/core/app_router.dart';
import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/widgets/profile_avatar.dart';
import 'package:chat/core/database/tables.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/chat/chat_repository.dart';
import 'package:chat/features/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContactListItem extends ConsumerWidget {
  final Contact contact;
  final Function(BuildContext, WidgetRef, Contact) confirmDelete;

  const ContactListItem({
    super.key,
    required this.contact,
    required this.confirmDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesStream = ref.watch(chatStreamProvider(contact.id));

    final int colorIndex =
        contact.alias.hashCode.abs() % AppColors.avatarColors.length;
    final Color avatarColor = AppColors.avatarColors[colorIndex];

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRouter.chat, arguments: contact);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Slidable(
            key: ValueKey(contact.id),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.6,
              children: [
                CustomSlidableAction(
                  onPressed: (context) {
                    confirmDelete(context, ref, contact);
                  },
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
                        'Delete',
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
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ProfileAvatar(
                        imageData: contact.profilePicture,
                        radius: 32,
                        backgroundColor: avatarColor.withValues(alpha: 0.2),
                        iconColor: avatarColor,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 64,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        contact.alias,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (contact.status ==
                                          ContactStatus.pendingOut)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'Pending',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  messagesStream.maybeWhen(
                                    data: (messages) {
                                      if (messages.isEmpty) {
                                        return const SizedBox.shrink();
                                      }

                                      final latestMessage = messages.first;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: Text(
                                          formatDateTimeContact(
                                            latestMessage.timestamp,
                                          ),
                                        ),
                                      );
                                    },
                                    loading: () => const Text('...'),
                                    error: (_, _) => const Text('Error'),
                                    orElse: () => const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    messagesStream.maybeWhen(
                                      data: (messages) => messages.isNotEmpty
                                          ? messages.first.content
                                          : 'No messages',
                                      loading: () => 'Loading...',
                                      error: (_, _) => 'Error loading messages',
                                      orElse: () => '',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  messagesStream.when(
                                    data: (messages) {
                                      final unreadCount = messages
                                          .where(
                                            (m) =>
                                                !m.isFromMe &&
                                                m.status ==
                                                    MessageStatus.delivered,
                                          )
                                          .length;

                                      if (unreadCount == 0) {
                                        return const SizedBox.shrink();
                                      }

                                      return Padding(
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
                                            maxLines: 1,
                                            overflow: TextOverflow.clip,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall!
                                                .copyWith(
                                                  color: AppColors.white,
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                    error: (e, st) => SizedBox.shrink(),
                                    loading: () => SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
