import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/chat.dart';
import '../../providers/auth_controller.dart';
import '../../services/chat_service.dart';

class CommunitiesTab extends StatelessWidget {
  const CommunitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final companyId = profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: StreamBuilder<List<ChatThread>>(
        stream: ChatService().watchChats(),
        builder: (context, snapshot) {
          final groups = (snapshot.data ?? [])
              .where((chat) => chat.isGroup)
              .where((chat) => companyId.isEmpty || chat.companyId == companyId || chat.companyId.isEmpty)
              .toList();
          return ListView(
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.teal,
                  child: const Icon(Icons.apartment, color: Colors.white),
                ),
                title: Text(
                  companyId.isEmpty ? 'Your company' : 'Company workspace',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  companyId.isEmpty
                      ? 'Ask admin to seed the company, then you will see departments here.'
                      : 'Announcements, departments, and office groups',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/company'),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('GROUPS', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              if (groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyHint(
                    icon: Icons.groups_outlined,
                    title: 'No communities yet',
                    subtitle: 'Create a group chat, or wait for admin to add department groups.',
                  ),
                )
              else
                ...groups.map(
                  (chat) => ListTile(
                    leading: UserAvatar(name: chat.name.isEmpty ? 'Group' : chat.name, photoUrl: chat.photoUrl),
                    title: Text(chat.name.isEmpty ? 'Group' : chat.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage, maxLines: 1),
                    onTap: () => Navigator.pushNamed(context, '/chat', arguments: chat),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/new-group'),
        child: const Icon(Icons.group_add),
      ),
    );
  }
}
