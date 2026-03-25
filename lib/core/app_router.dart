import 'package:chat/core/database/app_database.dart';
import 'package:chat/core/theme/theme.dart';
import 'package:chat/core/widgets/qr_scanner_sheet.dart';
import 'package:chat/features/chat/chat_screen.dart';
import 'package:chat/features/contacts/blocked_contacts_screen.dart';
import 'package:chat/features/contacts/contact_details_screen.dart';
import 'package:chat/features/contacts/contact_request_screen.dart';
import 'package:chat/features/groups/create_group_screen.dart';
import 'package:chat/features/groups/group_chat_screen.dart';
import 'package:chat/features/groups/group_details_screen.dart';
import 'package:chat/features/key_management/key_controller.dart';
import 'package:chat/features/main/main_screen.dart';
import 'package:chat/features/profile/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/contacts/add_contact_screen.dart';
import '../features/contacts/contacts_list_screen.dart';
import '../features/key_management/key_screen.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static const String authWrapper = '/';
  static const String mainScreen = '/main_screen';
  static const String onboarding = '/onboarding';
  static const String contacts = '/contacts';
  static const String addContact = '/add_contact';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String contactDetails = '/contact_details';
  static const String contactRequests = '/contact_requests';
  static const String blockedContacts = '/blocked_contacts';
  static const String qrScanner = '/qr_scanner';
  static const String createGroup = '/create_group';
  static const String groupChat = '/group_chat';
  static const String groupDetails = '/group_details';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case mainScreen:
        return CupertinoPageRoute(builder: (_) => const MainScreen());
      case authWrapper:
        return CupertinoPageRoute(builder: (_) => const AuthGuard());
      case onboarding:
        return CupertinoPageRoute(builder: (_) => const OnboardingScreen());
      case contacts:
        return CupertinoPageRoute(builder: (_) => const ContactsListScreen());
      case addContact:
        return CupertinoPageRoute(builder: (_) => const AddContactScreen());
      case profile:
        return CupertinoPageRoute(builder: (_) => const ProfileScreen());
      case contactRequests:
        return CupertinoPageRoute(
          builder: (_) => const ContactRequestsScreen(),
        );
      case blockedContacts:
        return CupertinoPageRoute(
          builder: (_) => const BlockedContactsScreen(),
        );
      case chat:
        final contact = settings.arguments as Contact;
        return CupertinoPageRoute(builder: (_) => ChatScreen(contact: contact));
      case contactDetails:
        final contact = settings.arguments as Contact;
        return CupertinoPageRoute(
          builder: (_) => ContactDetailsScreen(contact: contact),
        );
      case qrScanner:
        final onScan = settings.arguments as Function(String);
        return CupertinoPageRoute(
          builder: (_) => QrScannerScreen(onScanned: onScan),
        );
      case createGroup:
        return CupertinoPageRoute(builder: (_) => const CreateGroupScreen());
      case groupChat:
        final group = settings.arguments as Group;
        return CupertinoPageRoute(builder: (_) => GroupChatScreen(group: group));
      case groupDetails:
        final group = settings.arguments as Group;
        return CupertinoPageRoute(
          builder: (_) => GroupDetailsScreen(group: group),
        );
      default:
        return CupertinoPageRoute(builder: (_) => MainScreen());
    }
  }
}

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyState = ref.watch(keyControllerProvider);

    if (keyState.isLoading) {
      //TODO: loading screen
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.white)),
      );
    }

    if (keyState.isKeySetupComplete) {
      return const MainScreen();
    }

    return const OnboardingScreen();
  }
}
