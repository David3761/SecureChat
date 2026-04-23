import 'package:chat/core/theme/theme.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cipher', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
