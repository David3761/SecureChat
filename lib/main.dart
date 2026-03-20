import 'package:chat/core/app_router.dart';
import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/core/security/crypto_service.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/contacts/contact_request_controller.dart';
import 'package:chat/features/contacts/contact_request_modal.dart';
import 'package:chat/features/disappearing_messages/disappearing_service.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:chat/mask_traffic/traffic_masking_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final cryptoService = CryptoService();
  await cryptoService.init();

  runApp(
    ProviderScope(
      overrides: [cryptoServiceProvider.overrideWithValue(cryptoService)],
      child: const AppEntry(),
    ),
  );
}

class AppEntry extends ConsumerStatefulWidget {
  const AppEntry({super.key});

  @override
  ConsumerState<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<AppEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(disappearingMessagesServiceProvider).start();

      final pubKey = ref.read(keyControllerProvider).publicKeyHex;
      if (pubKey != null) {
        final enabled = await ref
            .read(secureStorageProvider)
            .getMaskTrafficEnabled(pubKey);
        if (enabled) {
          ref.read(trafficMaskingServiceProvider).start();
        }
      }
    });
  }

  void _showRequestModal(BuildContext context, Contact contact) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigatorContext = AppRouter.navigatorKey.currentContext;
      if (navigatorContext == null) return;

      showModalBottomSheet(
        context: navigatorContext,
        isDismissible: false,
        backgroundColor: Colors.transparent,
        builder: (_) => ContactRequestModal(contact: contact),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(contactRequestControllerProvider, (previous, contact) {
      if (contact != null && previous == null) {
        _showRequestModal(context, contact);
      }
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zero-Knowledge Chat',
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.authWrapper,
      onGenerateRoute: AppRouter.generateRoute,
      navigatorKey: AppRouter.navigatorKey,
    );
  }
}
