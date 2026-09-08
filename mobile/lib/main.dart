import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/attendance/attendance_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/phone_screen.dart';
import 'features/auth/profile_setup_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/chat/new_chat_screen.dart';
import 'features/company/company_hub_screen.dart';
import 'features/contacts/contacts_tab.dart';
import 'features/home/home_shell.dart';
import 'features/profile/settings_screen.dart';
import 'firebase_options.dart';
import 'models/chat.dart';
import 'providers/auth_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission();
  runApp(const ArMessengerApp());
}

class ArMessengerApp extends StatelessWidget {
  const ArMessengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthGate(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/otp':
              return MaterialPageRoute(builder: (_) => const OtpScreen());
            case '/new-chat':
              return MaterialPageRoute(builder: (_) => const NewChatScreen());
            case '/new-group':
              return MaterialPageRoute(builder: (_) => const NewGroupScreen());
            case '/chat':
              return MaterialPageRoute(
                builder: (_) => ChatScreen(chat: settings.arguments as ChatThread),
              );
            case '/search':
              return MaterialPageRoute(builder: (_) => const SearchScreen());
            case '/settings':
              return MaterialPageRoute(builder: (_) => const SettingsScreen());
            case '/company':
              return MaterialPageRoute(builder: (_) => const CompanyHubScreen());
            case '/attendance':
              return MaterialPageRoute(builder: (_) => const AttendanceScreen());
            case '/attendance-history':
              return MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen());
            case '/notices':
              return MaterialPageRoute(builder: (_) => const NoticesScreen());
            default:
              return null;
          }
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (auth.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!auth.isSignedIn) {
      return const PhoneScreen();
    }
    if (auth.needsProfile) {
      return const ProfileSetupScreen();
    }
    return const HomeShell();
  }
}
