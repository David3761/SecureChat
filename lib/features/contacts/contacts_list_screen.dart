import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:chat/core/app_router.dart';
import 'package:chat/core/database/tables.dart';
import 'package:chat/core/network/connection_controller.dart';
import 'package:chat/core/providers.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/core/widgets/contact_list_item.dart';
import 'package:chat/core/widgets/group_list_item.dart';
import 'package:chat/features/contacts/new_chat_bottomsheet.dart';
import 'package:chat/features/groups/group_repository.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/app_database.dart';
import 'contacts_repository.dart';

class ContactsListScreen extends ConsumerStatefulWidget {
  const ContactsListScreen({super.key});

  @override
  ConsumerState<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends ConsumerState<ContactsListScreen> {
  final TextEditingController _searchbarController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchbarController.dispose();
    super.dispose();
  }

  void _showNewChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NewChatSheet(),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Contact contact,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text(
          'Are you sure you want to remove ${contact.alias}? This will not delete your message history, but you will need their public key to message them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repository = ref.read(contactsRepositoryProvider);
      if (repository == null) throw Exception('Database not ready.');
      await repository.deleteContact(contact.id);
    }
  }

  Future<void> _confirmLeaveGroup(
    BuildContext context,
    WidgetRef ref,
    Group group,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group?'),
        content: const Text(
          'Are you sure you want to leave this group? You will no longer receive messages from it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final groupRepo = ref.read(groupRepositoryProvider);
      if (groupRepo == null) throw Exception('Database not ready.');
      await groupRepo.deleteGroup(group.groupId);
    }
  }

  void _showEllipsisMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.userClock),
                title: const Text('Contact Requests'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRouter.contactRequests);
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.ban),
                title: const Text('Blocked Contacts'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRouter.blockedContacts);
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.userGroup),
                title: const Text('New Group'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRouter.createGroup);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrScanner(BuildContext context) {
    Navigator.pushNamed(context, AppRouter.qrScanner, arguments: _handleQrScan);
  }

  Future<void> _handleQrScan(String pubKey) async {
    final keyState = ref.read(keyControllerProvider);
    if (keyState.publicKeyHex == pubKey) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("That's your own QR code.")));
      return;
    }

    final contactsRepo = ref.read(contactsRepositoryProvider);
    if (contactsRepo == null) return;

    final existing = await contactsRepo.getContactByPublicKey(pubKey);
    if (existing != null && existing.status == ContactStatus.active) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This user is already in your contacts.'),
          ),
        );
      }
      return;
    }

    final storageService = ref.read(secureStorageProvider);
    final cryptoService = ref.read(cryptoServiceProvider);
    final wsService = ref.read(webSocketServiceProvider);
    final myPubKey = await storageService.getLastActiveAccount();
    if (myPubKey == null) return;

    final myNickname = keyState.nickname ?? 'User${myPubKey.substring(0, 5)}';
    final defaultSeconds = await storageService.getDefaultDisappearingSeconds(
      myPubKey,
    );

    if (existing == null) {
      await contactsRepo.addContact(
        alias: pubKey.substring(0, 8),
        publicKey: pubKey,
        disappearingAfterSeconds: defaultSeconds,
        status: ContactStatus.pendingOut,
      );
    }

    final encryptedBlob = cryptoService.encryptMessage(
      plainText: jsonEncode({
        'type': 'contact_request',
        'nickname': myNickname,
        'qr_initiated': true,
      }),
      mySecretKey: keyState.activeSecretKey!,
      theirPublicKeyHex: pubKey,
    );

    wsService.sendMessage(
      messageId: const Uuid().v4(),
      senderPubKey: myPubKey,
      recipientPubKey: pubKey,
      encryptedBlob: encryptedBlob,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsyncValue = ref.watch(contactsStreamProvider);
    final groupsAsyncValue = ref.watch(groupsStreamProvider);
    final connectionState = ref.watch(connectionControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          if (connectionState == ConnectionState.disconnected ||
              connectionState == ConnectionState.error ||
              connectionState == ConnectionState.connecting)
            Material(
              color: AppColors.onSecondaryBackground,
              child: SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  alignment: Alignment.center,
                  child: Text(
                    connectionState == ConnectionState.error ||
                            connectionState == ConnectionState.disconnected
                        ? 'You are offline'
                        : 'Connecting...',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: HeaderDelegate(
                    safeAreaTop: MediaQuery.paddingOf(context).top,
                    backgroundColor: AppColors.background,
                    scrolledColor: AppColors.secondaryBackground.withValues(
                      alpha: 0.10,
                    ),
                    onAddPressed: () => _showNewChatSheet(context),
                    onScanPressed: () => _showQrScanner(context),
                    onEllipsisPressed: () => _showEllipsisMenu(context),
                    searchBarBuilder: (textOpacity) => SearchBar(
                      controller: _searchbarController,
                      onChanged: _onSearchChanged,
                      constraints: const BoxConstraints(
                        maxHeight: 40,
                        minHeight: 40,
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 10.0),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      leading: Icon(
                        Icons.search_rounded,
                        size: 24,
                        color: AppColors.onSecondaryBackground.withValues(
                          alpha: textOpacity,
                        ),
                      ),
                      elevation: WidgetStateProperty.all(0),
                      backgroundColor: WidgetStateProperty.all(
                        AppColors.secondaryBackground,
                      ),
                      hintText: 'Search',
                      hintStyle: WidgetStateProperty.all(
                        TextStyle(
                          color: AppColors.onSecondaryBackground.withValues(
                            alpha: textOpacity,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Groups
                groupsAsyncValue.maybeWhen(
                  data: (groups) {
                    final filtered = groups
                        .where(
                          (g) =>
                              _searchQuery.isEmpty ||
                              (g.name ?? '')
                                  .toLowerCase()
                                  .contains(_searchQuery),
                        )
                        .toList();
                    if (filtered.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                      sliver: SliverList.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => GroupListItem(
                          group: filtered[index],
                          confirmDelete: _confirmLeaveGroup,
                        ),
                      ),
                    );
                  },
                  orElse: () =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

                // Contacts
                contactsAsyncValue.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => SliverFillRemaining(
                    child: Center(child: Text('Error: $error')),
                  ),
                  data: (contacts) {
                    final filteredContacts = contacts
                        .where(
                          (c) => c.alias.toLowerCase().contains(_searchQuery),
                        )
                        .toList();

                    final groups =
                        groupsAsyncValue.asData?.value ?? const [];
                    final bothEmpty =
                        filteredContacts.isEmpty && groups.isEmpty;

                    if (bothEmpty && _searchQuery.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'Your vault is empty.\nTap the + button to add a contact.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }

                    if (filteredContacts.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                      sliver: SliverList.builder(
                        itemCount: filteredContacts.length,
                        itemBuilder: (context, index) => ContactListItem(
                          contact: filteredContacts[index],
                          confirmDelete: _confirmDelete,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderDelegate extends SliverPersistentHeaderDelegate {
  final double safeAreaTop;
  final Widget Function(double textOpacity) searchBarBuilder;
  final Color backgroundColor;
  final Color scrolledColor;
  final VoidCallback onAddPressed;
  final VoidCallback onScanPressed;
  final VoidCallback onEllipsisPressed;

  HeaderDelegate({
    required this.safeAreaTop,
    required this.searchBarBuilder,
    required this.backgroundColor,
    required this.scrolledColor,
    required this.onAddPressed,
    required this.onScanPressed,
    required this.onEllipsisPressed,
  });

  @override
  double get minExtent => safeAreaTop + 60.0;

  @override
  double get maxExtent => safeAreaTop + 60.0 + 50.0 + 60.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    const double topBarHeight = 60.0;
    const double largeTitleHeight = 50.0;
    const double searchBarHeight = 60.0;

    double searchShrink = shrinkOffset.clamp(0.0, searchBarHeight);
    double searchProgress = searchShrink / searchBarHeight;

    double textOpacity = (1.0 - (searchProgress / 0.15)).clamp(0.0, 1.0);

    double titleShrink = (shrinkOffset - searchBarHeight).clamp(
      0.0,
      largeTitleHeight,
    );
    double titleProgress = titleShrink / largeTitleHeight;

    final currentBgColor = Color.lerp(
      backgroundColor,
      scrolledColor,
      titleProgress,
    );

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          decoration: BoxDecoration(
            color: currentBgColor,
            border: Border(
              bottom: BorderSide(
                color: AppColors.onSecondaryBackground.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: searchBarHeight - searchShrink,
                child: Opacity(
                  opacity: 1.0 - searchProgress,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width,
                      height: searchBarHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22.0,
                          vertical: 8.0,
                        ),
                        child: searchBarBuilder(textOpacity),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: safeAreaTop,
                left: 0,
                right: 0,
                height: topBarHeight + largeTitleHeight - titleShrink,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 16,
                      top: 14,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryBackground,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: onEllipsisPressed,
                          padding: EdgeInsets.zero,
                          icon: const FaIcon(
                            FontAwesomeIcons.ellipsis,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 56,
                      top: 14,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryBackground,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: onScanPressed,
                          padding: EdgeInsets.zero,
                          icon: const FaIcon(
                            FontAwesomeIcons.camera,
                            size: 16,
                            color: AppColors.onSecondaryBackground,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: 14,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryBackground,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: onAddPressed,
                          padding: EdgeInsets.zero,
                          icon: const FaIcon(
                            FontAwesomeIcons.plus,
                            size: 16,
                            color: AppColors.onSecondaryBackground,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      top: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22.0),
                        child: Align(
                          alignment: Alignment.lerp(
                            const Alignment(-1.0, 0.6),
                            const Alignment(0.0, 0.0),
                            titleProgress,
                          )!,
                          child: Text(
                            'Chats',
                            style: TextStyle(
                              fontSize: Tween<double>(
                                begin: 32.0,
                                end: 20.0,
                              ).transform(titleProgress),
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.displayMedium?.color ??
                                  Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant HeaderDelegate oldDelegate) => true;
}
