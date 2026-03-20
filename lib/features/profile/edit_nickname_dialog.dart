import 'package:chat/features/key_management/key_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showEditNicknameDialog(
  BuildContext context,
  String publicKey,
  String currentNickname,
  VoidCallback loadAccounts,
  WidgetRef ref,
) async {
  final controller = TextEditingController(text: currentNickname);

  final platform = Theme.of(context).platform;
  final isIOS = platform == TargetPlatform.iOS;

  final newName = await showAdaptiveDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog.adaptive(
        title: const Text('Edit Profile Name'),
        content: isIOS
            ? CupertinoTextField(
                controller: controller,
                placeholder: 'Enter new name',
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              )
            : TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Enter new name'),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
        actions: [
          if (isIOS) ...[
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ],
      );
    },
  );

  if (newName != null && newName.isNotEmpty && newName != currentNickname) {
    await ref.read(keyControllerProvider.notifier).updateNickname(newName);
    loadAccounts();
  }
}
