import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_controller.dart';
import '../../services/user_service.dart';

class ContactsTab extends StatelessWidget {
  const ContactsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user?.uid ?? '';
    return Scaffold(
      appBar: const MessengerAppBar(title: 'Contacts'),
      body: StreamBuilder<List<UserProfile>>(
        stream: UserService().contacts(),
        builder: (context, snapshot) {
          final users = (snapshot.data ?? []).where((u) => u.id != me).toList();
          if (users.isEmpty) {
            return const EmptyHint(
              icon: Icons.people_outline,
              title: 'No contacts',
              subtitle: 'People who register with AR Messenger will appear here.',
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: UserAvatar(name: user.displayName, photoUrl: user.photoUrl),
                title: Text(user.displayName),
                subtitle: Text(
                  user.isOnline ? 'Online' : user.phone,
                  style: TextStyle(color: user.isOnline ? AppColors.accent : AppColors.muted),
                ),
                onTap: () => Navigator.pushNamed(context, '/new-chat'),
              );
            },
          );
        },
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Search people',
            hintStyle: TextStyle(color: Colors.white70),
            filled: false,
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
        ),
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: UserService().contacts(),
        builder: (context, snapshot) {
          final users = (snapshot.data ?? [])
              .where((u) => u.id != me)
              .where((u) => u.displayName.toLowerCase().contains(_query) || u.phone.contains(_query))
              .toList();
          return ListView(
            children: users
                .map(
                  (user) => ListTile(
                    leading: UserAvatar(name: user.displayName, photoUrl: user.photoUrl),
                    title: Text(user.displayName),
                    subtitle: Text(user.phone),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
