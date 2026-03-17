import 'dart:async';
import 'dart:ui';
import 'package:chat/core/network/connection_controller.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/core/widgets/contact_list_item.dart';
import 'package:chat/features/contacts/new_chat_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      final repository = await ref.read(contactsRepositoryProvider.future);
      await repository.deleteContact(contact.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsyncValue = ref.watch(contactsStreamProvider);
    final connectionState = ref.watch(connectionControllerProvider);
    //TODO: update ui on disconnect

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
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
              searchBarBuilder: (textOpacity) => SearchBar(
                controller: _searchbarController,
                onChanged: _onSearchChanged,
                constraints: const BoxConstraints(maxHeight: 40, minHeight: 40),
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
          contactsAsyncValue.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $error')),
            ),
            data: (contacts) {
              if (contacts.isEmpty) {
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

              final filteredContacts = contacts.where((contact) {
                return contact.alias.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filteredContacts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No contacts found.')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 22.0),
                sliver: SliverList.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    return ContactListItem(
                      contact: filteredContacts[index],
                      confirmDelete: _confirmDelete,
                    );
                  },
                ),
              );
            },
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

  HeaderDelegate({
    required this.safeAreaTop,
    required this.searchBarBuilder,
    required this.backgroundColor,
    required this.scrolledColor,
    required this.onAddPressed,
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
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          icon: const FaIcon(
                            FontAwesomeIcons.ellipsis,
                            size: 16,
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
