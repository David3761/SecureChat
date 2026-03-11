import 'package:chat/features/key_management/key_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_router.dart';
import '../../core/providers.dart';

class AccountDrawer extends ConsumerStatefulWidget {
  const AccountDrawer({super.key});

  @override
  ConsumerState<AccountDrawer> createState() => _AccountDrawerState();
}

class _AccountDrawerState extends ConsumerState<AccountDrawer> {
  List<String> _knownAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final storage = ref.read(secureStorageProvider);
    final accounts = await storage.getKnownAccounts();
    setState(() => _knownAccounts = accounts);
  }

  void _handleLogout() {
    ref.read(keyControllerProvider.notifier).logout();
    Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
  }

  void _handleSwitchAccount(String pubKey) {
    ref.read(keyControllerProvider.notifier).login(pubKey);
    Navigator.of(context).pop();
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
          Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
        }
      } else {
        _loadAccounts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePubKey = ref.watch(keyControllerProvider).publicKeyHex;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.shield, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Active Account',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  activePubKey != null
                      ? '${activePubKey.substring(0, 8)}...${activePubKey.substring(activePubKey.length - 8)}'
                      : 'Not Logged In',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'SAVED ACCOUNTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _knownAccounts.length,
              itemBuilder: (context, index) {
                final accountKey = _knownAccounts[index];
                final isActive = accountKey == activePubKey;

                return ListTile(
                  leading: Icon(
                    isActive
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isActive
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  title: Text(
                    '${accountKey.substring(0, 8)}...',
                    style: const TextStyle(fontFamily: 'Courier'),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () => _handleDeleteAccount(accountKey),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _knownAccounts[index]),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: isActive
                      ? null
                      : () => _handleSwitchAccount(accountKey),
                );
              },
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Another Account'),
            onTap: _handleLogout,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
