import 'package:chat/core/app_router.dart';
import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/core/security/crypto_service.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/app_lock/app_lock_service.dart';
import 'package:chat/features/contacts/contact_request_controller.dart';
import 'package:chat/features/contacts/contact_request_modal.dart';
import 'package:chat/features/disappearing_messages/disappearing_service.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:chat/features/mask_traffic/traffic_masking_service.dart';
import 'package:chat/features/tor/tor_bootstrapping_dialog.dart';
import 'package:chat/features/tor/tor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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

class _AppEntryState extends ConsumerState<AppEntry>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    switch (lifecycleState) {
      case AppLifecycleState.paused:
        ref.read(appLockProvider.notifier).onAppBackgrounded();
        break;
      case AppLifecycleState.resumed:
        ref.read(appLockProvider.notifier).onAppResumed();
        break;
      default:
        break;
    }
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

    ref.listen(torProvider, (previous, next) {
      final status = next.value;
      final prevStatus = previous?.value;

      if (status == TorStatus.bootstrapping &&
          prevStatus != TorStatus.bootstrapping) {
        showDialog(
          context: AppRouter.navigatorKey.currentContext!,
          barrierDismissible: false,
          builder: (_) => const TorBootstrappingDialog(),
        );
      } else if (status != TorStatus.bootstrapping &&
          prevStatus == TorStatus.bootstrapping) {
        final ctx = AppRouter.navigatorKey.currentContext;
        if (ctx != null) Navigator.of(ctx, rootNavigator: true).pop();
      }
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zero-Knowledge Chat',
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.authWrapper,
      onGenerateRoute: AppRouter.generateRoute,
      navigatorKey: AppRouter.navigatorKey,
      builder: (context, child) {
        final lockAsync = ref.watch(appLockProvider);

        final shouldHide = lockAsync.when(
          loading: () => false,
          error: (_, _) => false,
          data: (state) => state.isLocked && state.isEnabled,
        );

        return Stack(
          children: [
            child!,
            if (shouldHide)
              const Material(color: Colors.black, child: SizedBox.expand()),
          ],
        );
      },
    );
  }
}
