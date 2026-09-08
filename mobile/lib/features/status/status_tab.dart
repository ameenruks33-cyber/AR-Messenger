import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/status_post.dart';
import '../../providers/auth_controller.dart';
import '../../services/status_service.dart';

class StatusTab extends StatelessWidget {
  const StatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user?.uid ?? '';
    final profile = context.watch<AuthController>().profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: StreamBuilder<List<StatusPost>>(
        stream: StatusService().watchActive(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyHint(
              icon: Icons.cloud_off,
              title: 'Status unavailable',
              subtitle: 'Check your connection, then try posting again.',
            );
          }
          final posts = snapshot.data ?? [];
          final mine = posts.where((post) => post.userId == me).toList();
          final others = posts.where((post) => post.userId != me).toList();
          return ListView(
            children: [
              ListTile(
                leading: Stack(
                  children: [
                    UserAvatar(name: profile?.displayName ?? 'You', photoUrl: profile?.photoUrl, radius: 26),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.accent,
                        child: const Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                title: const Text('My status', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  mine.isEmpty ? 'Tap to add photo, text, voice, or location' : mine.first.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _compose(context),
              ),
              if (others.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('RECENT UPDATES', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ...others.map(
                (post) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: UserAvatar(name: post.displayName, photoUrl: post.photoUrl, radius: 24),
                  ),
                  title: Text(post.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    DateFormat('h:mm a').format(post.createdAt),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  onTap: () => _view(context, post),
                ),
              ),
              if (posts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: EmptyHint(
                    icon: Icons.camera_outlined,
                    title: 'No status yet',
                    subtitle: 'Share a photo-free text update. It disappears after 24 hours.',
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _compose(context),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Future<void> _compose(BuildContext context) async {
    final profile = context.read<AuthController>().profile;
    if (profile == null) return;
    final text = TextEditingController();
    String type = 'text';
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('New status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(label: const Text('Text'), selected: type == 'text', onSelected: (_) => setModal(() => type = 'text')),
                      ChoiceChip(label: const Text('Photo'), selected: type == 'image', onSelected: (_) => setModal(() => type = 'image')),
                      ChoiceChip(label: const Text('Voice'), selected: type == 'audio', onSelected: (_) => setModal(() => type = 'audio')),
                      ChoiceChip(label: const Text('Location'), selected: type == 'location', onSelected: (_) => setModal(() => type = 'location')),
                      if (profile.isManagerOrAbove)
                        ChoiceChip(label: const Text('Announcement'), selected: type == 'announcement', onSelected: (_) => setModal(() => type = 'announcement')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: text,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'What is happening?'),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: 'Post',
                    onPressed: () async {
                      var value = text.text.trim();
                      if (value.isEmpty) {
                        value = switch (type) {
                          'image' => 'Photo',
                          'audio' => 'Voice status',
                          'location' => 'Location',
                          'announcement' => 'Company announcement',
                          _ => '',
                        };
                      }
                      if (value.isEmpty) return;
                      await StatusService().post(profile: profile, text: value, type: type);
                      if (context.mounted) Navigator.pop(context, true);
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    text.dispose();
    if (posted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status posted for 24 hours')));
    }
  }

  void _view(BuildContext context, StatusPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.primaryDark,
          appBar: AppBar(
            title: Text(post.displayName),
            backgroundColor: Colors.transparent,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                post.text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600, height: 1.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
