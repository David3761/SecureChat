import 'package:chat/core/app_router.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  Map<String, String> _accounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final storage = ref.read(secureStorageProvider);
    final accounts = await storage.getKnownAccounts();
    final map = <String, String>{};
    for (final pubKey in accounts) {
      final name = await storage.getNickname(pubKey);
      map[pubKey] = name ?? 'Unknown account';
    }
    if (!mounted) return;
    if (map.isEmpty) {
      Navigator.of(context).pushReplacementNamed(AppRouter.signup);
      return;
    }
    setState(() {
      _accounts = map;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(keyControllerProvider, (previous, next) {
      if (previous?.isKeySetupComplete == false &&
          next.isKeySetupComplete == true) {
        Navigator.of(context).pushReplacementNamed(AppRouter.mainScreen);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select an account to continue.',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: AppColors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            height: MediaQuery.of(context).size.height * 1.9 / 3,
            child: SafeArea(
              top: false,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        SizedBox(height: 64),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                            children: [
                              ..._accounts.entries.map((entry) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: const Icon(Icons.person),
                                    title: Text(
                                      entry.value,
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${entry.key.substring(0, 8)}...${entry.key.substring(entry.key.length - 8)}',
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => ref
                                        .read(keyControllerProvider.notifier)
                                        .login(entry.key),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushReplacementNamed(AppRouter.signup),
                                child: Text(
                                  'New here? Sign up',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
