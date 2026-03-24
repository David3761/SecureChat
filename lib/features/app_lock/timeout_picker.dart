import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/app_lock/app_lock_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showTimeoutPicker(BuildContext context, WidgetRef ref) {
  final options = [
    (30, '30 seconds'),
    (60, '1 minute'),
    (120, '2 minutes'),
    (300, '5 minutes'),
    (600, '10 minutes'),
  ];

  final currentTimeout = ref.read(appLockProvider).value?.timeoutSeconds ?? 60;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSecondaryBackground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Lock after',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = currentTimeout == option.$1;
                final isLast = index == options.length - 1;

                return Column(
                  children: [
                    ListTile(
                      title: Text(option.$2),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primaryBlue,
                              size: 18,
                            )
                          : null,
                      onTap: () async {
                        await ref
                            .read(appLockProvider.notifier)
                            .setTimeout(option.$1);
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
