import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/chat.dart';
import '../../models/employee.dart';
import '../../providers/auth_controller.dart';
import '../../services/chat_service.dart';
import '../../services/workplace_service.dart';

class CommunitiesTab extends StatelessWidget {
  const CommunitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final companyId = profile?.companyId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Communities')),
      body: StreamBuilder<List<ChatThread>>(
        stream: ChatService().watchChats(),
        builder: (context, snapshot) {
          final groups = (snapshot.data ?? []).where((chat) => chat.isGroup).toList();
          return ListView(
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.teal, child: Icon(Icons.apartment, color: Colors.white)),
                title: const Text('ANRG COMPANY', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(companyId.isEmpty ? 'Ask admin to seed the company workspace.' : 'Announcements, departments, and offices'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/company'),
              ),
              const Divider(),
              StreamBuilder<List<Employee>>(
                stream: WorkplaceService().employees(companyId),
                builder: (context, empSnap) {
                  final departments = (empSnap.data ?? []).map((e) => e.department.isEmpty ? 'General' : e.department).toSet().toList()..sort();
                  if (departments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text('CHANNELS', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text('CHANNELS', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      ...{'Announcements', 'Management', ...departments}.map(
                            (name) => ListTile(
                              leading: Icon(_iconFor(name), color: AppColors.teal),
                              title: Text(name),
                              onTap: () => Navigator.pushNamed(context, '/company'),
                            ),
                          ),
                    ],
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('GROUPS', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              if (groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyHint(
                    icon: Icons.groups_outlined,
                    title: 'No community groups yet',
                    subtitle: 'Create a group chat for leasing, maintenance, security, or an office.',
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

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('announce')) return Icons.campaign;
    if (lower.contains('manage')) return Icons.badge;
    if (lower.contains('leas')) return Icons.home_work;
    if (lower.contains('main')) return Icons.build;
    if (lower.contains('secur')) return Icons.security;
    if (lower.contains('dubai') || lower.contains('sharjah') || lower.contains('abu')) return Icons.location_on;
    return Icons.groups;
  }
}
