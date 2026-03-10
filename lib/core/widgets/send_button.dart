import 'package:chat/features/chat/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SendButton extends ConsumerWidget {
  final int contactId;
  final VoidCallback onPressed;

  const SendButton({
    super.key,
    required this.contactId,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      chatControllerProvider(contactId).select((s) => s.isLoading),
    );

    return CircleAvatar(
      backgroundColor: Theme.of(context).primaryColor,
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(10.0),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: onPressed,
            ),
    );
  }
}
