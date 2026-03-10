import 'package:chat/core/app_router.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'core/security/crypto_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cryptoService = CryptoService();
  await cryptoService.init();

  runApp(
    ProviderScope(
      overrides: [cryptoServiceProvider.overrideWithValue(cryptoService)],
      child: const SecureChatApp(),
    ),
  );
}

class SecureChatApp extends StatelessWidget {
  const SecureChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zero-Knowledge Chat',
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.onboarding,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
