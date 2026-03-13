import 'package:chat/core/app_router.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'key_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _keyController = TextEditingController();
  String? _inputError;
  List<String> _knownAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final storage = ref.read(secureStorageProvider);
    final accounts = await storage.getKnownAccounts();
    if (mounted) {
      setState(() => _knownAccounts = accounts);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);

    if (!mounted) return;

    final pastedText = clipboardData?.text?.replaceAll(' ', '').trim();

    if (pastedText == null || pastedText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clipboard is empty.')));
      return;
    }

    final hexRegex = RegExp(r'^[0-9a-fA-F]{64}$');
    if (hexRegex.hasMatch(pastedText)) {
      _keyController.text = pastedText;
      setState(() => _inputError = null);

      await Clipboard.setData(const ClipboardData(text: ''));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Clipboard does not contain a valid 64-character hex key.',
          ),
        ),
      );
    }
  }

  void _validateAndImport() {
    final key = _keyController.text.replaceAll(' ', '').trim();

    if (key.isEmpty) {
      setState(() => _inputError = 'Please enter a private key.');
      return;
    }

    final hexRegex = RegExp(r'^[0-9a-fA-F]{64}$');
    if (!hexRegex.hasMatch(key)) {
      setState(
        () => _inputError = 'Key must be exactly 64 valid hex characters.',
      );
      return;
    }

    setState(() => _inputError = null);

    _keyController.clear();

    ref.read(keyControllerProvider.notifier).importAndSaveKey(key);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(keyControllerProvider, (previous, next) {
      final wasNotLoggedIn = previous?.isKeySetupComplete == false;
      final isNowLoggedIn = next.isKeySetupComplete == true;

      if (wasNotLoggedIn && isNowLoggedIn) {
        Navigator.of(context).pushReplacementNamed(AppRouter.mainScreen);
      }
    });

    final state = ref.watch(keyControllerProvider);
    final textTheme = Theme.of(context).textTheme;

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
                      'Welcome!',
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We offer the privacy you've been looking for.",
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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            height: MediaQuery.of(context).size.height * 2.2 / 3,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //TODO: better UI here
                    if (_knownAccounts.isNotEmpty) ...[
                      Text(
                        'Log back in',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ..._knownAccounts.map(
                        (pubKey) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(
                              state.nickname ?? 'Unknown account',
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ref
                                  .read(keyControllerProvider.notifier)
                                  .login(pubKey);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(thickness: 1, color: AppColors.grey),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              'OR',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(thickness: 1, color: AppColors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                    Text(
                      'Get Started',
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () => ref
                                .read(keyControllerProvider.notifier)
                                .generateAndSaveKey(),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Generate New Key'),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(thickness: 1, color: AppColors.grey),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'OR BRING YOUR OWN',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.grey,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Expanded(
                          child: Divider(thickness: 1, color: AppColors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _keyController,
                      onChanged: (_) {
                        if (_inputError != null) {
                          setState(() => _inputError = null);
                        }
                      },
                      maxLines: 3,
                      minLines: 1,
                      style: textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Courier',
                        letterSpacing: 1.3,
                        color: AppColors.title,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter Your Private Key',
                        errorText: _inputError,
                        labelStyle: _inputError != null
                            ? textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              )
                            : null,
                        floatingLabelStyle: _inputError != null
                            ? textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              )
                            : null,
                        suffixIcon: IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.clipboard,
                            color: _inputError != null
                                ? Theme.of(context).colorScheme.error
                                : AppColors.grey,
                          ),
                          onPressed: _pasteFromClipboard,
                          tooltip: 'Paste from clipboard',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton(
                      onPressed: state.isLoading ? null : _validateAndImport,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Import Key'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
