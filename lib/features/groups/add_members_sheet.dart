import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:flutter/material.dart';

class AddMembersSheet extends StatefulWidget {
  final List<Contact> available;

  const AddMembersSheet({super.key, required this.available});

  @override
  State<AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends State<AddMembersSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 64),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Text(
                  'Add Members',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                TextButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, _selected),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: widget.available.length,
              itemBuilder: (context, index) {
                final contact = widget.available[index];
                final selected = _selected.contains(contact.publicKey);
                final colorIndex =
                    contact.alias.hashCode.abs() %
                    AppColors.avatarColors.length;
                final avatarColor = AppColors.avatarColors[colorIndex];
                return CheckboxListTile(
                  value: selected,
                  onChanged: (_) => setState(() {
                    if (selected) {
                      _selected.remove(contact.publicKey);
                    } else {
                      _selected.add(contact.publicKey);
                    }
                  }),
                  title: Text(contact.alias),
                  secondary: CircleAvatar(
                    backgroundColor: avatarColor.withValues(alpha: 0.2),
                    child: Text(
                      contact.alias[0].toUpperCase(),
                      style: TextStyle(color: avatarColor),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
