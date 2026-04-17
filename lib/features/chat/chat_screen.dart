import 'package:chat/core/app_router.dart';
import 'package:chat/core/database/tables.dart';
import 'package:chat/core/widgets/message_bubble.dart';
import 'package:chat/core/widgets/send_button.dart';
import 'package:chat/features/chat/chat_controller.dart';
import 'package:chat/features/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/database/app_database.dart';
import 'chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Contact contact;

  const ChatScreen({super.key, required this.contact});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      _messageController.clear();

      await ref
          .read(chatControllerProvider(widget.contact.id).notifier)
          .sendMessage(text, widget.contact);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  Future<void> _notifyMessagesRead(List<Message> messages) async {
    final unreadMessageIds = messages
        .where((m) => !m.isFromMe && m.status == MessageStatus.delivered)
        .map((m) => m.messageId)
        .toList();

    if (unreadMessageIds.isNotEmpty && mounted) {
      await ref
          .read(chatControllerProvider(widget.contact.id).notifier)
          .markAsReadAndNotify(widget.contact, unreadMessageIds);
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
    final messagesStream = ref.watch(chatStreamProvider(widget.contact.id));

    ref.listen(chatControllerProvider(widget.contact.id), (previous, next) {
      if (next is AsyncError) {
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
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.angleLeft),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.contactDetails,
            arguments: widget.contact,
          ),
          child: Text(widget.contact.alias),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (widget.contact.status == ContactStatus.pendingOut)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Messages will be delivered once they accept your request',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(
                child: messagesStream.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (messages) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _notifyMessagesRead(messages);
                    });

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet.\nSend a message to start the secure channel.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final lastMessage = messages.first;
                    final String? showSeenOnId =
                        (lastMessage.isFromMe &&
                            lastMessage.status == MessageStatus.read)
                        ? lastMessage.messageId
                        : null;

                    final List<Widget> items = [];

                    for (int i = 0; i < messages.length; i++) {
                      final message = messages[i];
                      final isMe = message.isFromMe;
                      final showSeen = message.messageId == showSeenOnId;

                      items.add(
                        MessageBubble(
                          message: message,
                          isMe: isMe,
                          showSeen: showSeen,
                          onRetry: message.status == MessageStatus.failed
                              ? () => ref
                                    .read(
                                      chatControllerProvider(
                                        widget.contact.id,
                                      ).notifier,
                                    )
                                    .retryMessage(
                                      message.messageId,
                                      widget.contact,
                                    )
                              : null,
                        ),
                      );

                      if (i + 1 < messages.length) {
                        final olderMessage = messages[i + 1];
                        final gap = message.timestamp.difference(
                          olderMessage.timestamp,
                        );

                        if (gap.inMinutes >= 60) {
                          items.add(
                            _buildSeparator(context, message.timestamp),
                          );
                        }
                      }
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) => items[index],
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
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
                        contactId: widget.contact.id,
                        onPressed: _sendMessage,
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
    );
  }
}
