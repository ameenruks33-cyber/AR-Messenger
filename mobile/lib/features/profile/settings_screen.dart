import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../providers/auth_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: UserAvatar(
              name: profile?.displayName ?? 'You',
              photoUrl: profile?.photoUrl,
              radius: 28,
            ),
            title: Text(
              profile?.displayName ?? 'You',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(profile?.phone ?? '', style: const TextStyle(color: AppColors.muted)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.apartment_outlined, color: AppColors.teal),
            title: const Text('Company'),
            subtitle: const Text('Attendance, directory, announcements'),
            onTap: () => Navigator.pushNamed(context, '/company'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.teal),
            title: const Text('Privacy'),
            subtitle: const Text('Last seen and read receipts follow your chats'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: AppColors.teal),
            title: const Text('Notifications'),
            subtitle: const Text('Message and attendance alerts'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline, color: AppColors.teal),
            title: const Text('Chats'),
            subtitle: const Text('Wallpaper and theme come next'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.storage_outlined, color: AppColors.teal),
            title: const Text('Storage and data'),
            subtitle: const Text('Media auto-download'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.teal),
            title: const Text('Help'),
            subtitle: const Text('AR Messenger V1'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out'),
            onTap: () => context.read<AuthController>().signOut(),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}
