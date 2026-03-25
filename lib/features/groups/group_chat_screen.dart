import 'package:chat/core/app_router.dart';
import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/database/tables.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/core/widgets/send_button.dart';
import 'package:chat/features/groups/group_controller.dart';
import 'package:chat/features/groups/group_repository.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:chat/features/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupChatScreen({super.key, required this.group});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 100;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage(List<GroupMember> members) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await ref
          .read(groupChatControllerProvider(widget.group.groupId).notifier)
          .sendMessage(text, members);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  String _resolveAlias(
    String senderPubKey,
    List<GroupMember> members,
    String myPubKey,
  ) {
    if (senderPubKey == myPubKey) return 'You';
    try {
      return members.firstWhere((m) => m.publicKey == senderPubKey).alias;
    } catch (_) {
      return '${senderPubKey.substring(0, 4)}...${senderPubKey.substring(senderPubKey.length - 4)}';
    }
  }

  Widget _buildSeparator(BuildContext context, DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              formatConversationSeparator(dt),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      groupMessagesStreamProvider(widget.group.groupId),
    );
    final membersAsync = ref.watch(
      groupMembersStreamProvider(widget.group.groupId),
    );
    final myPubKey = ref.watch(
      keyControllerProvider.select((s) => s.publicKeyHex ?? ''),
    );

    final String groupName;
    final rawName = widget.group.name;
    if (rawName != null && rawName.isNotEmpty) {
      groupName = rawName;
    } else {
      groupName = membersAsync.maybeWhen(
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

    final memberCount = membersAsync.maybeWhen(
      data: (m) => m.length,
      orElse: () => 0,
    );

    ref.listen(groupChatControllerProvider(widget.group.groupId), (_, next) {
      if (next is AsyncError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: ${next.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.groupDetails,
            arguments: widget.group,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(groupName),
              if (memberCount > 0)
                Text(
                  '$memberCount members',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: messagesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (messages) {
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'No messages yet.\nSay hello to the group!',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final List<Widget> items = [];

                      for (int i = 0; i < messages.length; i++) {
                        final msg = messages[i];
                        final isMe = msg.isFromMe;

                        items.add(
                          _GroupMessageBubble(
                            message: msg,
                            isMe: isMe,
                            senderAlias: isMe
                                ? null
                                : _resolveAlias(
                                    msg.senderPubKey,
                                    members,
                                    myPubKey,
                                  ),
                          ),
                        );

                        if (i + 1 < messages.length) {
                          final gap = msg.timestamp.difference(
                            messages[i + 1].timestamp,
                          );
                          if (gap.inMinutes >= 60) {
                            items.add(_buildSeparator(context, msg.timestamp));
                          }
                        }
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: items.length,
                        itemBuilder: (_, index) => items[index],
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 7,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SendButton(
                          contactId: 0,
                          onPressed: () => _sendMessage(members),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showScrollToBottom)
              Positioned(
                bottom: 120,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _showScrollToBottom ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _scrollToBottom,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupMessageBubble extends StatelessWidget {
  final GroupMessage message;
  final bool isMe;
  final String? senderAlias;

  const _GroupMessageBubble({
    required this.message,
    required this.isMe,
    this.senderAlias,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('HH:mm').format(message.timestamp);
    final aliasColor = senderAlias != null
        ? AppColors.avatarColors[senderAlias!.hashCode.abs() %
              AppColors.avatarColors.length]
        : Colors.transparent;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
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
            if (!isMe && senderAlias != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderAlias!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: aliasColor,
                  ),
                ),
              ),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMe && message.status == MessageStatus.failed)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.error_outline,
                      size: 14,
                      color: Colors.redAccent,
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }
}
