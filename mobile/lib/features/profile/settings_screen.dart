import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          const SizedBox(height: 16),
          Center(
            child: UserAvatar(
              name: profile?.displayName ?? 'You',
              photoUrl: profile?.photoUrl,
              radius: 42,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              profile?.displayName ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          Center(child: Text(profile?.phone ?? '')),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Role'),
            subtitle: Text(profile?.role.replaceAll('_', ' ') ?? 'employee'),
          ),
          ListTile(
            leading: const Icon(Icons.apartment_outlined),
            title: const Text('Employee ID'),
            subtitle: Text(profile?.employeeId.isEmpty == true ? 'Not linked yet' : profile!.employeeId),
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
