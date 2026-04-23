import 'dart:ui';

import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/app_lock/app_lock_info.dart';
import 'package:chat/features/app_lock/app_lock_service.dart';
import 'package:chat/features/app_lock/timeout_picker.dart';
import 'package:chat/features/disappearing_messages/show_disappearing_picker.dart';
import 'package:chat/features/mask_traffic/show_traffic_mask_info.dart';
import 'package:chat/core/widgets/profile_avatar.dart';
import 'package:chat/features/profile/edit_nickname_dialog.dart';
import 'package:chat/features/profile/my_profile_repository.dart';
import 'package:chat/features/profile/profile_picture_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat/core/widgets/settings_option.dart';
import 'package:chat/core/widgets/titled_settings_section.dart';
import 'package:chat/features/profile/show_qr_modal.dart';
import 'package:chat/features/mask_traffic/mask_traffic_provider.dart';
import 'package:chat/features/tor/tor_info.dart';
import 'package:chat/features/tor/tor_toggle_notifier.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/app_router.dart';
import '../../core/providers.dart';
import '../../core/widgets/skeleton_bone.dart';
import '../../core/widgets/skeletonizer.dart';
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

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final controller = ref.read(profilePictureControllerProvider);
                final bytes = await controller.pickAndCompress(
                  source: ImageSource.camera,
                );
                if (bytes != null) {
                  await controller.updateMyProfilePicture(bytes);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final controller = ref.read(profilePictureControllerProvider);
                final bytes = await controller.pickAndCompress();
                if (bytes != null) {
                  await controller.updateMyProfilePicture(bytes);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
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

  Widget _buildSkeletonSettingsCard(
    BuildContext context, {
    required double labelWidth,
    required List<Widget> rows,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: SkeletonBone(width: labelWidth, height: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: AppColors.white,
            ),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonScaffold(
    BuildContext context,
    double topPadding,
    double minScrollHeight,
  ) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      body: Skeletonizer(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 250.0 + topPadding,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: topPadding),
                      const SkeletonBone(
                        width: 116,
                        height: 116,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(height: 16),
                      SkeletonBone(width: 140, height: 22),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              sliver: SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minScrollHeight),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildSkeletonSettingsCard(
                        context,
                        labelWidth: 110,
                        rows: [
                          const ListTile(
                            leading: SkeletonBone(
                              width: 40,
                              height: 40,
                              shape: BoxShape.circle,
                            ),
                            title: SkeletonBone(width: 130, height: 14),
                            subtitle: SkeletonBone(width: 90, height: 12),
                          ),
                          const Divider(height: 1, indent: 72, endIndent: 16),
                          const ListTile(
                            leading: SkeletonBone(
                              width: 40,
                              height: 40,
                              shape: BoxShape.circle,
                            ),
                            title: SkeletonBone(width: 130, height: 14),
                            subtitle: SkeletonBone(width: 90, height: 12),
                          ),
                          const Divider(height: 1, indent: 72, endIndent: 16),
                          const ListTile(
                            leading: SkeletonBone(width: 24, height: 24),
                            title: SkeletonBone(width: 80, height: 14),
                          ),
                        ],
                      ),
                      _buildSkeletonSettingsCard(
                        context,
                        labelWidth: 60,
                        rows: [
                          const ListTile(
                            leading: SkeletonBone(width: 22, height: 22),
                            title: SkeletonBone(width: 140, height: 14),
                          ),
                          const Divider(height: 1, indent: 56),
                          const ListTile(
                            leading: SkeletonBone(width: 22, height: 22),
                            title: SkeletonBone(width: 110, height: 14),
                          ),
                          const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: const SkeletonBone(width: 22, height: 22),
                            title: const SkeletonBone(width: 70, height: 14),
                            trailing: const SkeletonBone(width: 40, height: 24),
                          ),
                          const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: const SkeletonBone(width: 22, height: 22),
                            title: const SkeletonBone(width: 95, height: 14),
                            trailing: const SkeletonBone(width: 40, height: 24),
                          ),
                          const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: const SkeletonBone(width: 22, height: 22),
                            title: const SkeletonBone(width: 130, height: 14),
                            trailing: const SkeletonBone(width: 40, height: 24),
                          ),
                          const Divider(height: 1, indent: 56),
                          const ListTile(
                            leading: SkeletonBone(width: 22, height: 22),
                            title: SkeletonBone(width: 60, height: 14),
                          ),
                          const Divider(height: 1, indent: 56),
                          const ListTile(
                            leading: SkeletonBone(width: 22, height: 22),
                            title: SkeletonBone(width: 100, height: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
    final myPicData = ref.watch(myProfilePictureProvider).asData?.value;
    final topPadding = MediaQuery.of(context).padding.top;

    final minScrollHeight =
        MediaQuery.of(context).size.height - (kToolbarHeight + topPadding);

    if (_isLoadingAccounts) {
      return _buildSkeletonScaffold(context, topPadding, minScrollHeight);
    }

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: ProfileHeaderDelegate(
              paddingTop: topPadding,
              activeNickname: activeNickname,
              profilePicData: myPicData,
              onTapAvatar: _showAvatarOptions,
              onEditNickname: () => showEditNicknameDialog(
                context,
                activePubKey,
                activeNickname,
                _loadAccounts,
                ref,
              ),
              onShowQr: () =>
                  showQrModal(context, activePubKey, _copyToClipboard),
              backgroundColor: AppColors.secondaryBackground,
              scrolledColor: AppColors.secondaryBackground.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0),
            sliver: SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minScrollHeight),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    TitledSettingsSection(
                      title: "Switch profile",
                      options: _accountNicknames.length > 1
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
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
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
                          callback: () => showDisappearingPicker(
                            context,
                            ref,
                            mounted,
                            activePubKey,
                          ),
                          hasArrow: true,
                        ),
                        SettingsOption(
                          title: 'Blocked contacts',
                          iconData: FontAwesomeIcons.ban,
                          callback: () => Navigator.pushNamed(
                            context,
                            AppRouter.blockedContacts,
                          ),
                          hasArrow: true,
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
                          callback: () {
                            if (ref.read(appLockProvider).value?.isEnabled ==
                                true) {
                              showTimeoutPicker(context, ref);
                            }
                          },
                          hasArrow: false,
                          onInfoPressed: () => showAppLockInfo(context),
                          trailing: ref
                              .watch(appLockProvider)
                              .maybeWhen(
                                data: (lockState) => Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: lockState.isEnabled,
                                    onChanged: (_) => ref
                                        .read(appLockProvider.notifier)
                                        .toggleEnabled(),
                                    activeThumbColor: AppColors.primaryBlue,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                orElse: () => const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                        ),
                        SettingsOption(
                          title: 'Mask traffic',
                          iconData: FontAwesomeIcons.server,
                          callback: () {},
                          hasArrow: false,
                          onInfoPressed: () => showMaskTrafficInfo(context),
                          trailing: ref
                              .watch(maskTrafficProvider)
                              .maybeWhen(
                                data: (enabled) => Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: enabled,
                                    onChanged: (_) => ref
                                        .read(maskTrafficProvider.notifier)
                                        .toggle(),
                                    activeThumbColor: AppColors.primaryBlue,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                orElse: () => const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                        ),
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
                          hasArrow: false,
                          onInfoPressed: () => showTorInfo(context),
                          trailing: ref
                              .watch(torToggleProvider)
                              .maybeWhen(
                                data: (enabled) => Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: enabled,
                                    onChanged: (_) => ref
                                        .read(torToggleProvider.notifier)
                                        .toggle(context),
                                    activeThumbColor: AppColors.primaryBlue,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                orElse: () => const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
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
  final Uint8List? profilePicData;
  final VoidCallback? onTapAvatar;

  ProfileHeaderDelegate({
    required this.paddingTop,
    required this.activeNickname,
    required this.onEditNickname,
    required this.onShowQr,
    required this.backgroundColor,
    required this.scrolledColor,
    this.profilePicData,
    this.onTapAvatar,
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
                        child: ProfileAvatar(
                          imageData: profilePicData,
                          radius: 58,
                          backgroundColor: AppColors.primaryBlue.withValues(
                            alpha: 0.2,
                          ),
                          iconColor: AppColors.primaryBlue,
                          iconSize: 38,
                          onTap: onTapAvatar,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Opacity(
                        opacity: expandedOpacityName,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 48),
                            Flexible(
                              child: Text(
                                activeNickname,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
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
        scrolledColor != oldDelegate.scrolledColor ||
        profilePicData != oldDelegate.profilePicData;
  }
}
