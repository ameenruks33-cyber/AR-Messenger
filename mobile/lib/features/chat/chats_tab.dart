import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/chat.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_controller.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Messenger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'AR AI',
            onPressed: () => Navigator.pushNamed(context, '/ai'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') Navigator.pushNamed(context, '/settings');
              if (value == 'group') Navigator.pushNamed(context, '/new-group');
              if (value == 'company') Navigator.pushNamed(context, '/company');
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'group', child: Text('New group')),
              PopupMenuItem(value: 'company', child: Text('Company')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: const _ChatList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/new-chat'),
        child: const Icon(Icons.chat),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList();

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user?.uid ?? '';
    return StreamBuilder<List<ChatThread>>(
      stream: ChatService().watchChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return const EmptyHint(
            icon: Icons.chat_bubble_outline,
            title: 'No chats yet',
            subtitle: 'Tap the chat button to message a colleague or start a group.',
          );
        }
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            return FutureBuilder<UserProfile?>(
              future: _titleProfile(chat, me),
              builder: (context, profileSnap) {
                final other = profileSnap.data;
                final title = chat.isGroup
                    ? (chat.name.isEmpty ? 'Group' : chat.name)
                    : (other?.displayName.isEmpty == false ? other!.displayName : 'Chat');
                final photo = chat.isGroup ? chat.photoUrl : (other?.photoUrl ?? '');
                final time = chat.lastMessageAt == null
                    ? ''
                    : DateFormat('h:mm a').format(chat.lastMessageAt!);
                final online = !chat.isGroup && other?.isOnline == true;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Stack(
                    children: [
                      UserAvatar(name: title, photoUrl: photo, radius: 26),
                      if (online)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    chat.lastMessage.isEmpty ? 'Tap to open chat' : chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(time, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      if (chat.pinned) const Icon(Icons.push_pin, size: 14, color: AppColors.teal),
                    ],
                  ),
                  onTap: () => Navigator.pushNamed(context, '/chat', arguments: chat),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<UserProfile?> _titleProfile(ChatThread chat, String me) async {
    if (chat.isGroup) return null;
    final other = chat.memberIds.firstWhere((id) => id != me, orElse: () => '');
    if (other.isEmpty) return null;
    return UserService().byId(other);
  }
}
