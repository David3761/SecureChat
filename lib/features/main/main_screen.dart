import 'package:chat/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../contacts/contacts_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [const ContactsListScreen(), const Placeholder()];

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = AppColors.grey;

    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.all(4.0),
                child: FaIcon(
                  _selectedIndex == 0
                      ? FontAwesomeIcons.solidComment
                      : FontAwesomeIcons.comment,
                  size: 24,
                  color: _selectedIndex == 0 ? activeColor : inactiveColor,
                ),
              ),
              label: "Contacts",
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.all(4.0),
                child: FaIcon(
                  _selectedIndex == 0
                      ? FontAwesomeIcons.user
                      : FontAwesomeIcons.solidUser,
                  size: 24,
                  color: _selectedIndex == 1 ? activeColor : inactiveColor,
                ),
              ),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
