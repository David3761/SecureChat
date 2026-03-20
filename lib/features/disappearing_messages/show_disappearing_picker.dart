import 'package:chat/core/providers.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/disappearing_messages/disappearing_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showDisappearingPicker(
  BuildContext context,
  WidgetRef ref,
  bool mounted,
  String publicKey,
) async {
  final storage = ref.read(secureStorageProvider);
  final currentSeconds = await storage.getDefaultDisappearingSeconds(publicKey);

  if (!mounted || !context.mounted) return;

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.onSecondaryBackground.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Default disappearing messages',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: kDisappearingOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = currentSeconds == option.seconds;
                final isLast = index == kDisappearingOptions.length - 1;

                return Column(
                  children: [
                    ListTile(
                      title: Text(option.label),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primaryBlue,
                              size: 18,
                            )
                          : null,
                      onTap: () async {
                        await storage.saveDefaultDisappearingSeconds(
                          publicKey,
                          option.seconds,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                    if (!isLast)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}
