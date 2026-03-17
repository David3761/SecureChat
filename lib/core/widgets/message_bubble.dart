import 'package:chat/core/database/app_database.dart';
import 'package:chat/features/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showSeen;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSeen = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('HH:mm').format(message.timestamp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isMe
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: isMe
                  ? null
                  : Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe
                        ? Colors.white70
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showSeen)
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 4),
            child: Text(
              formatSeenAgo(message.readAt ?? message.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
