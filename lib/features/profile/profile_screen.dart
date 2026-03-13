import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_router.dart';
import '../../core/providers.dart';
import '../key_management/key_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, String> _accountNicknames = {};
  bool _isLoadingAccounts = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final storage = ref.read(secureStorageProvider);
    final accounts = await storage.getKnownAccounts();

    Map<String, String> nicknames = {};
    for (String pubKey in accounts) {
      final name = await storage.getNickname(pubKey);
      nicknames[pubKey] = name ?? 'Unknown Profile';
    }

    if (mounted) {
      setState(() {
        _accountNicknames = nicknames;
        _isLoadingAccounts = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
    }
  }

  Future<void> _showEditNicknameDialog(String currentNickname) async {
    final controller = TextEditingController(text: currentNickname);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new name'),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != currentNickname) {
      await ref.read(keyControllerProvider.notifier).updateNickname(newName);
      _loadAccounts();
    }
  }

  void _handleSwitchAccount(String pubKey) async {
    await ref.read(keyControllerProvider.notifier).login(pubKey);
    if (mounted) Navigator.pop(context);
  }

  void _handleLogout() async {
    await ref.read(keyControllerProvider.notifier).logout();
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.authWrapper, (_) => false);
    }
  }

  void _handleDeleteAccount(String pubKey) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently erase the private key and all messages for this account from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(keyControllerProvider.notifier).deleteAccount(pubKey);

      final activeKey = ref.read(keyControllerProvider).publicKeyHex;
      if (activeKey == null) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRouter.authWrapper, (route) => false);
        }
      } else {
        _loadAccounts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyState = ref.watch(keyControllerProvider);
    final activePubKey = keyState.publicKeyHex ?? '';
    final activeNickname = keyState.nickname ?? 'My Profile';

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.shield, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        activeNickname,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            _showEditNicknameDialog(activeNickname),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (activePubKey.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: activePubKey,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Text(
                    'YOUR PUBLIC KEY',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _copyToClipboard(activePubKey, 'Public Key'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              activePubKey,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_isLoadingAccounts && _accountNicknames.length > 1) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SWITCH PROFILE',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ..._accountNicknames.entries.map((entry) {
                final pubKey = entry.key;
                final nickname = entry.value;
                final isActive = pubKey == activePubKey;

                if (isActive) {
                  return const SizedBox.shrink();
                }

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    nickname,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${pubKey.substring(0, 8)}...${pubKey.substring(pubKey.length - 8)}',
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _handleDeleteAccount(pubKey),
                  ),
                  onTap: () => _handleSwitchAccount(pubKey),
                );
              }),
              const Divider(),
            ],

            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Another Profile'),
              onTap: _handleLogout,
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Log Out',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: _handleLogout,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
