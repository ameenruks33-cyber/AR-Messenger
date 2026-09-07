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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AR Messenger'),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () => Navigator.pushNamed(context, '/search')),
            IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.pushNamed(context, '/settings')),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Updates'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ChatList(),
            EmptyHint(
              icon: Icons.camera_outlined,
              title: 'Status updates',
              subtitle: 'Stories and company status will appear here in a later phase.',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/new-chat'),
          child: const Icon(Icons.add),
        ),
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
            subtitle: 'Start a conversation with a colleague or create a company group.',
          );
        }
        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
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
                    : DateFormat.Hm().format(chat.lastMessageAt!);
                return ListTile(
                  leading: UserAvatar(name: title, photoUrl: photo),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    chat.lastMessage.isEmpty ? 'Tap to open' : chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  trailing: Text(time, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
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
