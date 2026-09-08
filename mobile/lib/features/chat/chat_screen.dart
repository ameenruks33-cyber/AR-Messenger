import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/chat.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_controller.dart';
import '../../providers/prefs_controller.dart';
import '../../services/ai_service.dart';
import '../../services/chat_service.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../services/user_service.dart';
import '../../services/workplace_service.dart';
import '../ai/ar_ai_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chat});

  final ChatThread chat;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _search = TextEditingController();
  final _chat = ChatService();
  final _storage = StorageService();
  final _recorder = AudioRecorder();
  final _ai = ArAiService();
  Timer? _typingTimer;
  bool _recording = false;
  bool _searching = false;
  bool _unlocked = false;
  ChatMessage? _replyTo;
  UserProfile? _other;

  bool _gateChecked = false;

  @override
  void initState() {
    super.initState();
    _loadOther();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLock());
  }

  @override
  void dispose() {
    _text.dispose();
    _search.dispose();
    _recorder.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOther() async {
    if (widget.chat.isGroup) return;
    final me = context.read<AuthController>().user?.uid ?? '';
    final otherId = widget.chat.memberIds.firstWhere((id) => id != me, orElse: () => '');
    if (otherId.isEmpty) return;
    final profile = await UserService().byId(otherId);
    if (mounted) setState(() => _other = profile);
  }

  Future<void> _sendText() async {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    _text.clear();
    final thread = await _chat.byId(widget.chat.id);
    await _chat.sendMessage(
      chatId: widget.chat.id,
      type: 'text',
      text: value,
      replyTo: _replyTo?.id,
      disappearingHours: thread?.disappearingHours ?? 0,
    );
    await _chat.setTyping(widget.chat.id, false);
    setState(() => _replyTo = null);
  }

  Future<void> _sendPicked({required String type, required File file, required String name, required String contentType}) async {
    final ext = p.extension(file.path).replaceFirst('.', '');
    final url = await _storage.uploadChatMedia(
      chatId: widget.chat.id,
      file: file,
      contentType: contentType,
      extension: ext.isEmpty ? 'bin' : ext,
    );
    final thread = await _chat.byId(widget.chat.id);
    await _chat.sendMessage(
      chatId: widget.chat.id,
      type: type,
      mediaUrl: url,
      text: name,
      disappearingHours: thread?.disappearingHours ?? 0,
    );
  }

  Future<void> _sendFile({bool video = false}) async {
    final picked = await FilePicker.pickFile();
    if (picked?.path == null) return;
    final file = File(picked!.path!);
    final ext = p.extension(file.path).toLowerCase();
    final isVideo = video || ['.mp4', '.mov', '.mkv', '.webm'].contains(ext);
    await _sendPicked(
      type: isVideo ? 'video' : 'file',
      file: file,
      name: picked.name,
      contentType: isVideo ? 'video/mp4' : 'application/octet-stream',
    );
  }

  Future<void> _sendPhoto() async {
    final cameras = await availableCameras();
    if (!mounted || cameras.isEmpty) return;
    final file = await Navigator.of(context).push<File>(
      MaterialPageRoute(builder: (_) => _ChatCameraPage(cameras: cameras)),
    );
    if (file == null) return;
    await _sendPicked(type: 'image', file: file, name: 'Photo', contentType: 'image/jpeg');
  }

  Future<void> _sendLocation({bool live = false}) async {
    final fix = await LocationService().currentFix();
    final thread = await _chat.byId(widget.chat.id);
    await _chat.sendMessage(
      chatId: widget.chat.id,
      type: live ? 'live_location' : 'location',
      text: live ? 'Live location' : 'Location',
      latitude: fix.latitude,
      longitude: fix.longitude,
      disappearingHours: thread?.disappearingHours ?? 0,
    );
  }

  Future<void> _sendContact() async {
    final me = context.read<AuthController>().user?.uid ?? '';
    final users = await UserService().contacts().first;
    if (!mounted) return;
    final selected = await showModalBottomSheet<UserProfile>(
      context: context,
      builder: (context) => ListView(
        children: users
            .where((u) => u.id != me)
            .map(
              (user) => ListTile(
                title: Text(user.displayName),
                subtitle: Text(user.phone),
                onTap: () => Navigator.pop(context, user),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null) return;
    final thread = await _chat.byId(widget.chat.id);
    await _chat.sendMessage(
      chatId: widget.chat.id,
      type: 'contact',
      text: '${selected.displayName} ${selected.phone}',
      disappearingHours: thread?.disappearingHours ?? 0,
    );
  }

  Future<void> _toggleVoice() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path == null) return;
      await _sendPicked(type: 'audio', file: File(path), name: 'Voice message', contentType: 'audio/m4a');
      return;
    }
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() => _recording = true);
    }
  }

  void _onTyping(String value) {
    _chat.setTyping(widget.chat.id, value.isNotEmpty);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () => _chat.setTyping(widget.chat.id, false));
  }

  Future<void> _attachMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo), title: const Text('Photo'), onTap: () { Navigator.pop(context); _sendPhoto(); }),
            ListTile(leading: const Icon(Icons.videocam), title: const Text('Video'), onTap: () { Navigator.pop(context); _sendFile(video: true); }),
            ListTile(leading: const Icon(Icons.insert_drive_file), title: const Text('Document'), onTap: () { Navigator.pop(context); _sendFile(); }),
            ListTile(leading: const Icon(Icons.location_on), title: const Text('Location'), onTap: () { Navigator.pop(context); _sendLocation(); }),
            ListTile(leading: const Icon(Icons.my_location), title: const Text('Live location'), onTap: () { Navigator.pop(context); _sendLocation(live: true); }),
            ListTile(leading: const Icon(Icons.person), title: const Text('Contact'), onTap: () { Navigator.pop(context); _sendContact(); }),
          ],
        ),
      ),
    );
  }

  Future<void> _messageActions(ChatMessage message, String me) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.reply), title: const Text('Reply'), onTap: () { Navigator.pop(context); setState(() => _replyTo = message); }),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('React'),
              onTap: () async {
                Navigator.pop(context);
                final emoji = await showModalBottomSheet<String>(
                  context: this.context,
                  builder: (context) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['👍', '❤️', '😂', '😮', '🙏']
                        .map((e) => IconButton(onPressed: () => Navigator.pop(context, e), icon: Text(e, style: const TextStyle(fontSize: 24))))
                        .toList(),
                  ),
                );
                if (emoji != null) await _chat.react(chatId: widget.chat.id, messageId: message.id, emoji: emoji);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(message.starredBy.contains(me) ? 'Unstar' : 'Star / bookmark'),
              onTap: () {
                Navigator.pop(context);
                _chat.toggleStar(chatId: widget.chat.id, messageId: message.id, starred: !message.starredBy.contains(me));
              },
            ),
            ListTile(leading: const Icon(Icons.push_pin_outlined), title: const Text('Pin'), onTap: () { Navigator.pop(context); _chat.pinMessage(widget.chat.id, message.id); }),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                _forward(message);
              },
            ),
            if (message.senderId == me && message.type == 'text')
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _edit(message);
                },
              ),
            if (message.senderId == me)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _chat.deleteMessage(chatId: widget.chat.id, messageId: message.id);
                },
              ),
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('Create task'),
              onTap: () {
                Navigator.pop(context);
                _createTask(message.text);
              },
            ),
            if (message.type == 'text')
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.text));
                },
              ),
            if (message.type == 'audio')
              ListTile(
                leading: const Icon(Icons.notes),
                title: const Text('Convert to text'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog<void>(
                    context: this.context,
                    builder: (context) => AlertDialog(
                      title: const Text('Voice to text'),
                      content: Text(message.text.isEmpty ? 'Play the voice note, then use AR AI to rewrite what you heard. Cloud speech is not enabled on the free plan.' : message.text),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _forward(ChatMessage message) async {
    final chats = await _chat.watchChats().first;
    if (!mounted) return;
    final target = await showModalBottomSheet<ChatThread>(
      context: context,
      builder: (context) => ListView(
        children: chats
            .map(
              (chat) => ListTile(
                title: Text(chat.isGroup ? (chat.name.isEmpty ? 'Group' : chat.name) : 'Chat'),
                subtitle: Text(chat.lastMessage),
                onTap: () => Navigator.pop(context, chat),
              ),
            )
            .toList(),
      ),
    );
    if (target == null) return;
    await _chat.sendMessage(
      chatId: target.id,
      type: message.type,
      text: message.text,
      mediaUrl: message.mediaUrl,
      latitude: message.latitude,
      longitude: message.longitude,
    );
  }

  Future<void> _edit(ChatMessage message) async {
    final controller = TextEditingController(text: message.text);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;
    await _chat.editMessage(chatId: widget.chat.id, messageId: message.id, text: value);
  }

  Future<void> _createTask(String text) async {
    final profile = context.read<AuthController>().profile;
    if (profile == null) return;
    final title = _ai.extractTasks(text);
    await WorkplaceService().createTask(profile: profile, title: title.length > 180 ? text : title);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task created')));
    }
  }

  Future<void> _call(String kind) async {
    final phone = _other?.phone ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number on this chat yet.')));
      return;
    }
    await _chat.logCall(otherUid: _other!.id, kind: kind);
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _checkLock() async {
    final prefs = context.read<PrefsController>();
    if (!prefs.isLocked(widget.chat.id)) {
      setState(() {
        _unlocked = true;
        _gateChecked = true;
      });
      return;
    }
    setState(() => _gateChecked = true);
  }

  Future<bool> _unlockIfNeeded() async {
    final prefs = context.read<PrefsController>();
    if (!prefs.isLocked(widget.chat.id) || _unlocked) return true;
    final pin = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Locked chat'),
        content: TextField(
          controller: pin,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'PIN / fingerprint fallback'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unlock')),
        ],
      ),
    );
    if (ok != true) return false;
    if (prefs.chatPin.isNotEmpty && pin.text != prefs.chatPin) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong PIN')));
      return false;
    }
    setState(() => _unlocked = true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user?.uid ?? '';
    final prefs = context.watch<PrefsController>();
    final title = widget.chat.isGroup && widget.chat.name.isNotEmpty ? widget.chat.name : (_other?.displayName.isNotEmpty == true ? _other!.displayName : 'Chat');
    if (!_gateChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (prefs.isLocked(widget.chat.id) && !_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Locked chat')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.lock, size: 64, color: AppColors.teal),
              const SizedBox(height: 16),
              const Text('Fingerprint / Face / PIN'),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Unlock', onPressed: () async {
                final ok = await _unlockIfNeeded();
                if (ok && mounted) setState(() => _unlocked = true);
              }),
            ],
          ),
        ),
      );
    }
    return Scaffold(
          appBar: AppBar(
            title: _searching
                ? TextField(
                    controller: _search,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Search messages', hintStyle: TextStyle(color: Colors.white70), filled: false, border: InputBorder.none),
                    onChanged: (_) => setState(() {}),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      StreamBuilder<ChatThread?>(
                        stream: _chat.watchThread(widget.chat.id),
                        builder: (context, snapshot) {
                          final typing = snapshot.data?.typingUid ?? '';
                          final lastSeen = prefs.lastSeen == 'nobody' ? '' : (_other?.isOnline == true ? 'Online' : (_other?.lastSeen == null ? '' : 'Last seen ${DateFormat('h:mm a').format(_other!.lastSeen!)}'));
                          final subtitle = typing.isNotEmpty && typing != me ? 'typing…' : lastSeen;
                          if (subtitle.isEmpty) return const SizedBox.shrink();
                          return Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70));
                        },
                      ),
                    ],
                  ),
            actions: [
              IconButton(icon: const Icon(Icons.call), onPressed: () => _call('voice')),
              IconButton(icon: const Icon(Icons.videocam), onPressed: () => _call('video')),
              IconButton(icon: const Icon(Icons.smart_toy_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArAiScreen(chat: widget.chat)))),
              IconButton(
                icon: Icon(_searching ? Icons.close : Icons.search),
                onPressed: () => setState(() {
                  _searching = !_searching;
                  _search.clear();
                }),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'pin') await _chat.pinChat(widget.chat.id, !widget.chat.pinned);
                  if (value == 'lock') await prefs.toggleLock(widget.chat.id);
                  if (value == 'off') await _chat.setDisappearing(widget.chat.id, 0);
                  if (value == '24') await _chat.setDisappearing(widget.chat.id, 24);
                  if (value == '7') await _chat.setDisappearing(widget.chat.id, 24 * 7);
                  if (value == '90') await _chat.setDisappearing(widget.chat.id, 24 * 90);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'pin', child: Text(widget.chat.pinned ? 'Unpin chat' : 'Pin chat')),
                  PopupMenuItem(value: 'lock', child: Text(prefs.isLocked(widget.chat.id) ? 'Unlock chat' : 'Lock chat')),
                  const PopupMenuItem(value: 'off', child: Text('Disappearing: Off')),
                  const PopupMenuItem(value: '24', child: Text('Disappearing: 24 hours')),
                  const PopupMenuItem(value: '7', child: Text('Disappearing: 7 days')),
                  const PopupMenuItem(value: '90', child: Text('Disappearing: 90 days')),
                ],
              ),
            ],
          ),
          backgroundColor: AppColors.chatBg,
          body: Column(
            children: [
              StreamBuilder<ChatThread?>(
                stream: _chat.watchThread(widget.chat.id),
                builder: (context, snapshot) {
                  final pinnedId = snapshot.data?.pinnedMessageId ?? '';
                  if (pinnedId.isEmpty) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: Text('Pinned message', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
                  );
                },
              ),
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _chat.watchMessages(widget.chat.id),
                  builder: (context, snapshot) {
                    final query = _search.text.trim().toLowerCase();
                    final messages = (snapshot.data ?? []).where((m) {
                      if (query.isEmpty) return true;
                      return m.text.toLowerCase().contains(query);
                    }).toList();
                    for (final message in messages.take(8)) {
                      if (!message.readBy.contains(me)) {
                        _chat.markRead(widget.chat.id, message.id);
                      }
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final mine = message.senderId == me;
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: GestureDetector(
                            onLongPress: () => _messageActions(message, me),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: mine ? AppColors.outgoing : AppColors.incoming,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _MessageBody(message: message, mine: mine, showReceipts: prefs.readReceipts),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_replyTo != null)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text('Replying: ${_replyTo!.text}', maxLines: 1)),
                      IconButton(onPressed: () => setState(() => _replyTo = null), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
              SafeArea(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      IconButton(onPressed: _attachMenu, icon: const Icon(Icons.add_circle_outline)),
                      Expanded(
                        child: TextField(
                          controller: _text,
                          onChanged: _onTyping,
                          decoration: const InputDecoration(hintText: 'Message', filled: true),
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleVoice,
                        icon: Icon(_recording ? Icons.stop : Icons.mic_none, color: _recording ? AppColors.danger : AppColors.teal),
                      ),
                      IconButton(onPressed: _sendText, icon: const Icon(Icons.send, color: AppColors.teal)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.message, required this.mine, required this.showReceipts});

  final ChatMessage message;
  final bool mine;
  final bool showReceipts;

  @override
  Widget build(BuildContext context) {
    if (message.deleted) {
      return const Text('This message was deleted', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.muted));
    }
    Widget content;
    switch (message.type) {
      case 'image':
        content = message.mediaUrl.isEmpty
            ? const Text('Photo')
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(message.mediaUrl, width: 180, fit: BoxFit.cover),
              );
      case 'video':
        content = Row(children: [const Icon(Icons.play_circle), const SizedBox(width: 8), Flexible(child: Text(message.text.isEmpty ? 'Video' : message.text))]);
      case 'audio':
        content = _VoiceNote(url: message.mediaUrl);
      case 'file':
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_outlined, size: 18),
            const SizedBox(width: 8),
            Flexible(child: Text(message.text.isEmpty ? 'Document' : message.text)),
          ],
        );
      case 'location':
      case 'live_location':
        content = InkWell(
          onTap: () {
            final lat = message.latitude;
            final lng = message.longitude;
            if (lat == null || lng == null) return;
            launchUrl(Uri.parse('https://maps.google.com/?q=$lat,$lng'));
          },
          child: Row(children: [Icon(message.type == 'live_location' ? Icons.wifi_tethering : Icons.location_on), const SizedBox(width: 8), Text(message.text)]),
        );
      case 'contact':
        content = Row(children: [const Icon(Icons.person), const SizedBox(width: 8), Flexible(child: Text(message.text))]);
      default:
        content = Text(message.text);
    }
    final ticks = !mine || !showReceipts
        ? ''
        : (message.readBy.length > 1 ? ' ✓✓' : ' ✓');
    final reactions = message.reactions.values.toSet().join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (message.starredBy.isNotEmpty) const Align(alignment: Alignment.centerLeft, child: Text('⭐', style: TextStyle(fontSize: 12))),
        content,
        if (message.editedAt != null) const Text('edited', style: TextStyle(fontSize: 10, color: AppColors.muted)),
        if (reactions.isNotEmpty) Text(reactions, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          '${DateFormat.Hm().format(message.createdAt)}$ticks',
          style: TextStyle(fontSize: 10, color: ticks.contains('✓✓') ? AppColors.teal : AppColors.muted),
        ),
      ],
    );
  }
}

class _VoiceNote extends StatefulWidget {
  const _VoiceNote({required this.url});
  final String url;

  @override
  State<_VoiceNote> createState() => _VoiceNoteState();
}

class _VoiceNoteState extends State<_VoiceNote> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        if (_playing) {
          await _player.stop();
          setState(() => _playing = false);
        } else {
          await _player.play(UrlSource(widget.url));
          setState(() => _playing = true);
        }
      },
      icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
    );
  }
}

class _ChatCameraPage extends StatefulWidget {
  const _ChatCameraPage({required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<_ChatCameraPage> createState() => _ChatCameraPageState();
}

class _ChatCameraPageState extends State<_ChatCameraPage> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.cameras.first, ResolutionPreset.medium, enableAudio: false);
    _controller!.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(controller),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: FloatingActionButton(
                      onPressed: () async {
                        final shot = await controller.takePicture();
                        if (context.mounted) Navigator.pop(context, File(shot.path));
                      },
                      child: const Icon(Icons.camera),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
