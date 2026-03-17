import 'package:chat/core/app_router.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/contacts/contacts_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NewChatSheet extends ConsumerStatefulWidget {
  const NewChatSheet({super.key});

  @override
  ConsumerState<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends ConsumerState<NewChatSheet> {
  final TextEditingController _searchbarController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchbarController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.92,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.onSecondaryBackground.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    Text(
                      'New chat',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchBar(
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
                    color: AppColors.onSecondaryBackground,
                  ),
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(
                    AppColors.secondaryBackground,
                  ),
                  hintText: 'Search',
                  hintStyle: WidgetStateProperty.all(
                    TextStyle(color: AppColors.onSecondaryBackground),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _SheetAction(
                    icon: FontAwesomeIcons.userPlus,
                    iconColor: AppColors.onSecondaryBackground,
                    label: 'New contact',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.addContact);
                    },
                    showDivider: false,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Contacts',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppColors.onSecondaryBackground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: contactsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (contacts) {
                    final filteredContacts = contacts
                        .where(
                          (c) => c.alias.toLowerCase().contains(_searchQuery),
                        )
                        .toList();

                    if (filteredContacts.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No contacts yet.'
                              : 'No contacts found.',
                          style: TextStyle(
                            color: AppColors.onSecondaryBackground,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filteredContacts.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final contact = filteredContacts[index];
                        final colorIndex =
                            contact.alias.hashCode.abs() %
                            AppColors.avatarColors.length;
                        final avatarColor = AppColors.avatarColors[colorIndex];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: avatarColor.withValues(alpha: 0.2),
                            child: FaIcon(
                              FontAwesomeIcons.solidUser,
                              color: avatarColor,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            contact.alias,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRouter.chat,
                              arguments: contact,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  const _SheetAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: FaIcon(icon, size: 16, color: iconColor),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            color: AppColors.onSecondaryBackground.withValues(alpha: 0.1),
          ),
      ],
    );
  }
}
