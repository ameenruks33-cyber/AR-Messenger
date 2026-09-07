import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_controller.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../models/chat.dart';

class NewChatScreen extends StatelessWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('New chat'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/new-group'),
            child: const Text('New group', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: UserService().contacts(),
        builder: (context, snapshot) {
          final users = (snapshot.data ?? []).where((u) => u.id != me).toList();
          if (users.isEmpty) {
            return const Center(child: Text('No contacts yet. Ask colleagues to register.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: UserAvatar(name: user.displayName, photoUrl: user.photoUrl),
                title: Text(user.displayName),
                subtitle: Text(user.phone, style: const TextStyle(color: AppColors.muted)),
                onTap: () async {
                  final chatId = await ChatService().openDirectChat(user.id);
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(
                    context,
                    '/chat',
                    arguments: ChatThread(
                      id: chatId,
                      type: 'direct',
                      memberIds: [me, user.id],
                      name: user.displayName,
                      photoUrl: user.photoUrl,
                      lastMessage: '',
                      lastMessageAt: DateTime.now(),
                      createdBy: me,
                      companyId: '',
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _name = TextEditingController();
  final _selected = <String>{};
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Group name'),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: UserService().contacts(),
              builder: (context, snapshot) {
                final users = (snapshot.data ?? []).where((u) => u.id != me).toList();
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final checked = _selected.contains(user.id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selected.add(user.id);
                          } else {
                            _selected.remove(user.id);
                          }
                        });
                      },
                      title: Text(user.displayName),
                      secondary: UserAvatar(name: user.displayName, photoUrl: user.photoUrl),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              label: 'Create group',
              loading: _saving,
              onPressed: () async {
                if (_name.text.trim().isEmpty || _selected.isEmpty) return;
                setState(() => _saving = true);
                final companyId = context.read<AuthController>().profile?.companyId ?? '';
                final id = await ChatService().createGroup(
                  name: _name.text.trim(),
                  memberIds: _selected.toList(),
                  companyId: companyId,
                );
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(
                  context,
                  '/chat',
                  arguments: ChatThread(
                    id: id,
                    type: 'group',
                    memberIds: [..._selected, me],
                    name: _name.text.trim(),
                    photoUrl: '',
                    lastMessage: '',
                    lastMessageAt: DateTime.now(),
                    createdBy: me,
                    companyId: companyId,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
