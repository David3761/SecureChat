import 'package:chat/core/app_router.dart';
import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/chat/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class ContactListItem extends ConsumerWidget {
  final Contact contact;
  final Function(BuildContext, WidgetRef, Contact) confirmDelete;

  const ContactListItem({
    super.key,
    required this.contact,
    required this.confirmDelete,
  });

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final localDateTime = dateTime.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final diffInDays = now.difference(localDateTime).inDays;

    final timeString = DateFormat('HH:mm').format(localDateTime);

    if (localDateTime.isAfter(today)) {
      return timeString;
    } else if (localDateTime.isAfter(yesterday)) {
      return 'Yesterday';
    } else if (diffInDays <= 7) {
      return DateFormat('EEEE').format(localDateTime).toLowerCase();
    } else {
      return DateFormat('dd.MM.yyyy').format(localDateTime);
    }
  }

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
                      CircleAvatar(
                        minRadius: 32,
                        backgroundColor: avatarColor.withValues(alpha: 0.2),
                        //TODO: profile pic
                        child: FaIcon(
                          FontAwesomeIcons.solidUser,
                          color: avatarColor,
                        ),
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
                                  Text(
                                    contact.alias,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  messagesStream.maybeWhen(
                                    data: (messages) {
                                      if (messages.isEmpty) {
                                        return const SizedBox.shrink();
                                      }

                                      final latestMessage = messages.first;

                                      // TODO: Update this to read from the Message model
                                      final bool isUnread = true;

                                      //TODO: Ugly
                                      return Row(
                                        children: [
                                          if (isUnread) ...[
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: AppColors.primaryBlue,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            _formatDateTime(
                                              latestMessage.timestamp,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                    loading: () => const Text('...'),
                                    error: (_, _) => const Text('Error'),
                                    orElse: () => const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
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
