import 'package:chat/core/database/app_database.dart';
import 'package:chat/features/chat/chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../features/contacts/add_contact_screen.dart';
import '../features/contacts/contacts_list_screen.dart';
import '../features/key_management/key_screen.dart';

class AppRouter {
  static const String onboarding = '/';
  static const String contacts = '/contacts';
  static const String addContact = '/add_contact';
  static const String chat = '/chat';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return CupertinoPageRoute(builder: (_) => const OnboardingScreen());
      case contacts:
        return CupertinoPageRoute(builder: (_) => const ContactsListScreen());
      case addContact:
        return CupertinoPageRoute(builder: (_) => const AddContactScreen());
      case chat:
        final contact = settings.arguments as Contact;
        return CupertinoPageRoute(builder: (_) => ChatScreen(contact: contact));
      default:
        return CupertinoPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
