import 'package:chat/core/theme/theme.dart';
import 'package:flutter/material.dart';

void showAppLockInfo(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSecondaryBackground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'App Lock',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'When enabled, the app requires your device authentication (biometrics or PIN) after a period of inactivity.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Your device\'s existing security is used — no separate password is created. If you have biometrics set up, they will be used automatically.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'The app content is hidden while locked so it does not appear in the app switcher.',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.onSecondaryBackground,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}
