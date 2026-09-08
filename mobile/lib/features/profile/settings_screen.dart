import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../providers/auth_controller.dart';
import '../../providers/prefs_controller.dart';

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
            leading: UserAvatar(name: profile?.displayName ?? 'You', photoUrl: profile?.photoUrl, radius: 28),
            title: Text(profile?.displayName ?? 'You', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            subtitle: Text(profile?.phone ?? '', style: const TextStyle(color: AppColors.muted)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.apartment_outlined, color: AppColors.teal),
            title: const Text('Company'),
            subtitle: const Text('Attendance, directory, tasks, leave'),
            onTap: () => Navigator.pushNamed(context, '/company'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.teal),
            title: const Text('Privacy'),
            subtitle: const Text('Last seen, photo, read receipts, disappearing'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: AppColors.teal),
            title: const Text('Notifications'),
            subtitle: const Text('Message and attendance alerts'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: AppColors.teal),
            title: const Text('Chats and themes'),
            subtitle: const Text('Light, dark, AMOLED, chat lock PIN'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.teal),
            title: const Text('Help'),
            subtitle: const Text('AR Messenger 1.0.5'),
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

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PrefsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        children: [
          _Choice(title: 'Last seen', value: prefs.lastSeen, onChanged: prefs.setLastSeen),
          _Choice(title: 'Profile photo', value: prefs.profilePhoto, onChanged: prefs.setProfilePhoto),
          SwitchListTile(
            title: const Text('Read receipts'),
            value: prefs.readReceipts,
            onChanged: prefs.setReadReceipts,
          ),
          const ListTile(title: Text('Online status'), subtitle: Text('Same as last seen')),
          _Choice(
            title: 'Disappearing messages',
            value: prefs.disappearingDefault,
            options: const ['off', '24 hours', '7 days', '90 days'],
            onChanged: prefs.setDisappearing,
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.value,
    required this.onChanged,
    this.options = const ['everyone', 'contacts', 'nobody'],
  });

  final String title;
  final String value;
  final Future<void> Function(String) onChanged;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((option) => ListTile(title: Text(option), onTap: () => Navigator.pop(context, option))).toList(),
            ),
          ),
        );
        if (selected != null) await onChanged(selected);
      },
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PrefsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SwitchListTile(
        title: const Text('Message notifications'),
        subtitle: const Text('Alerts for chats, tasks, and attendance'),
        value: prefs.notifications,
        onChanged: prefs.setNotifications,
      ),
    );
  }
}

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PrefsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Chats and themes')),
      body: ListView(
        children: [
          ListTile(title: const Text('Light'), trailing: prefs.themeMode == ThemeMode.light && !prefs.amoled ? const Icon(Icons.check, color: AppColors.teal) : null, onTap: () => prefs.setTheme('light')),
          ListTile(title: const Text('Dark'), trailing: prefs.themeMode == ThemeMode.dark && !prefs.amoled ? const Icon(Icons.check, color: AppColors.teal) : null, onTap: () => prefs.setTheme('dark')),
          ListTile(title: const Text('AMOLED'), trailing: prefs.amoled ? const Icon(Icons.check, color: AppColors.teal) : null, onTap: () => prefs.setTheme('amoled')),
          const Divider(),
          ListTile(
            title: const Text('Chat lock PIN'),
            subtitle: Text(prefs.chatPin.isEmpty ? 'Not set' : 'PIN saved on this device'),
            onTap: () async {
              final pin = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Set PIN'),
                  content: TextField(controller: pin, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '4-6 digits')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
                  ],
                ),
              );
              if (ok == true && pin.text.trim().length >= 4) await prefs.setChatPin(pin.text.trim());
            },
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
