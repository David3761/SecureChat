import 'dart:ui';

import 'package:chat/core/theme/theme.dart';
import 'package:chat/core/widgets/settings_option.dart';
import 'package:chat/core/widgets/titled_settings_section.dart';
import 'package:chat/features/disappearing_messages/disappearing_options.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  Future<void> _showEditNicknameDialog(
    String publicKey,
    String currentNickname,
  ) async {
    final controller = TextEditingController(text: currentNickname);

    final platform = Theme.of(context).platform;
    final isIOS = platform == TargetPlatform.iOS;

    final newName = await showAdaptiveDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: const Text('Edit Profile Name'),
          content: isIOS
              ? CupertinoTextField(
                  controller: controller,
                  placeholder: 'Enter new name',
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                )
              : TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Enter new name'),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
          actions: [
            if (isIOS) ...[
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Save'),
              ),
            ] else ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
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
    final platform = Theme.of(context).platform;
    final isIOS = platform == TargetPlatform.iOS;

    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently erase the private key and all messages for this account from this device. This cannot be undone.',
        ),
        actions: [
          if (isIOS) ...[
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );

    if (confirm == true && mounted) {
      final keyController = ref.read(keyControllerProvider.notifier);
      final navigator = Navigator.of(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );

      await keyController.deleteAccount(pubKey);

      navigator.pushNamedAndRemoveUntil(
        AppRouter.authWrapper,
        (route) => false,
      );
    }
  }

  void showQrModal(String activePubKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'My QR Code',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: activePubKey,
                  version: QrVersions.auto,
                  size: 240.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'OR SEND YOUR PUBLIC KEY',
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
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
                      const SizedBox(width: 16),
                      const Icon(Icons.copy, size: 20, color: AppColors.grey),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDisappearingPicker(String publicKey) async {
    final storage = ref.read(secureStorageProvider);
    final currentSeconds = await storage.getDefaultDisappearingSeconds(
      publicKey,
    );

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSecondaryBackground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Default disappearing messages',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: kDisappearingOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = currentSeconds == option.seconds;
                  final isLast = index == kDisappearingOptions.length - 1;

                  return Column(
                    children: [
                      ListTile(
                        title: Text(option.label),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: AppColors.primaryBlue,
                                size: 18,
                              )
                            : null,
                        onTap: () async {
                          await storage.saveDefaultDisappearingSeconds(
                            publicKey,
                            option.seconds,
                          );
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

  @override
  Widget build(BuildContext context) {
    final keyState = ref.watch(keyControllerProvider);
    final activePubKey = keyState.publicKeyHex ?? '';
    final activeNickname = keyState.nickname ?? 'My Profile';
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: ProfileHeaderDelegate(
              paddingTop: topPadding,
              activeNickname: activeNickname,
              onEditNickname: () =>
                  _showEditNicknameDialog(activePubKey, activeNickname),
              onShowQr: () => showQrModal(activePubKey),
              backgroundColor: AppColors.secondaryBackground,
              scrolledColor: AppColors.secondaryBackground.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  TitledSettingsSection(
                    title: "Switch profile",
                    options: !_isLoadingAccounts && _accountNicknames.length > 1
                        ? [
                            ..._accountNicknames.entries
                                .where((entry) => entry.key != activePubKey)
                                .map((entry) {
                                  final pubKey = entry.key;
                                  final nickname = entry.value;
                                  return ListTile(
                                    key: ValueKey(pubKey),
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      nickname,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${pubKey.substring(0, 8)}...${pubKey.substring(pubKey.length - 8)}',
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 12,
                                      ),
                                    ),
                                    onTap: () => _handleSwitchAccount(pubKey),
                                  );
                                }),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: ListTile(
                                leading: const Icon(Icons.add),
                                title: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    'Add Profile',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                onTap: _handleLogout,
                              ),
                            ),
                          ]
                        : [
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('Add Profile'),
                              onTap: _handleLogout,
                            ),
                          ],
                  ),
                  TitledSettingsSection(
                    title: 'Security',
                    options: [
                      SettingsOption(
                        title: 'Dissappearing messages',
                        iconData: FontAwesomeIcons.clock,
                        callback: () => _showDisappearingPicker(activePubKey),
                      ),
                      SettingsOption(
                        title: 'Blocked contacts',
                        iconData: FontAwesomeIcons.ban,
                        callback: () => Navigator.pushNamed(
                          context,
                          AppRouter.blockedContacts,
                        ),
                      ),
                      SettingsOption(
                        title: 'App lock',
                        customIcon: SvgPicture.asset(
                          'assets/lock.svg',
                          width: 22,
                          height: 22,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).iconTheme.color!,
                            BlendMode.srcIn,
                          ),
                        ),
                        callback: () {},
                      ),
                      //TODO: prevent ss
                      SettingsOption(
                        title: 'Route through TOR',
                        customIcon: SvgPicture.asset(
                          'assets/tor.svg',
                          width: 22,
                          height: 22,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).iconTheme.color!,
                            BlendMode.srcIn,
                          ),
                        ),
                        callback: () {},
                      ),
                      SettingsOption(
                        title: 'Mask traffic',
                        iconData: FontAwesomeIcons.server,
                        callback: () {},
                      ),
                      SettingsOption(
                        title: 'Log Out',
                        iconData: FontAwesomeIcons.arrowRightFromBracket,
                        callback: _handleLogout,
                        hasArrow: false,
                        red: true,
                      ),
                      SettingsOption(
                        title: 'Delete Account',
                        iconData: FontAwesomeIcons.triangleExclamation,
                        callback: () => _handleDeleteAccount(activePubKey),
                        hasArrow: false,
                        red: true,
                        hasDivider: false,
                      ),
                    ],
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

class ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double paddingTop;
  final String activeNickname;
  final VoidCallback onEditNickname;
  final VoidCallback onShowQr;
  final Color backgroundColor;
  final Color scrolledColor;

  ProfileHeaderDelegate({
    required this.paddingTop,
    required this.activeNickname,
    required this.onEditNickname,
    required this.onShowQr,
    required this.backgroundColor,
    required this.scrolledColor,
  });

  @override
  double get minExtent => kToolbarHeight + paddingTop;

  @override
  double get maxExtent => 250.0 + paddingTop;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final shrinkPercentage = (shrinkOffset / (maxExtent - minExtent)).clamp(
      0.0,
      1.0,
    );

    final expandedOpacityName = (1 - shrinkPercentage * 8.0).clamp(0.0, 1.0);
    final expandedOpacityAvatar = (1 - shrinkPercentage * 3.0).clamp(0.0, 1.0);
    final collapsedOpacity = (shrinkPercentage * 4 - 1).clamp(0.0, 1.0);

    final currentBgColor = Color.lerp(
      backgroundColor,
      scrolledColor,
      shrinkPercentage,
    );

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: EdgeInsets.only(top: paddingTop),
          decoration: BoxDecoration(
            color: currentBgColor,
            border: Border(
              bottom: BorderSide(
                color: AppColors.onSecondaryBackground.withValues(
                  alpha: 0.15 * shrinkPercentage,
                ),
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 64,
                    horizontal: 24,
                  ),
                  child: Column(
                    children: [
                      Opacity(
                        opacity: expandedOpacityAvatar,
                        child: CircleAvatar(
                          radius: 58,
                          backgroundColor: AppColors.primaryBlue.withValues(
                            alpha: 0.2,
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.solidUser,
                            size: 38,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Opacity(
                        opacity: expandedOpacityName,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 48),
                            Text(
                              activeNickname,
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.grey,
                              ),
                              onPressed: onEditNickname,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Opacity(
                opacity: collapsedOpacity,
                child: Container(
                  height: kToolbarHeight,
                  alignment: Alignment.center,
                  child: Text(
                    activeNickname,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.darkerSecondaryBackground,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const FaIcon(
                      FontAwesomeIcons.qrcode,
                      color: AppColors.title,
                      size: 20,
                    ),
                    onPressed: onShowQr,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant ProfileHeaderDelegate oldDelegate) {
    return activeNickname != oldDelegate.activeNickname ||
        paddingTop != oldDelegate.paddingTop ||
        backgroundColor != oldDelegate.backgroundColor ||
        scrolledColor != oldDelegate.scrolledColor;
  }
}
