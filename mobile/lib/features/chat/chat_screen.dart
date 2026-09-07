import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../core/theme/app_theme.dart';
import '../../models/chat.dart';
import '../../providers/auth_controller.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chat});

  final ChatThread chat;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _chat = ChatService();
  final _storage = StorageService();
  final _recorder = AudioRecorder();
  bool _recording = false;
  ChatMessage? _replyTo;

  @override
  void dispose() {
    _text.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    _text.clear();
    await _chat.sendMessage(
      chatId: widget.chat.id,
      type: 'text',
      text: value,
      replyTo: _replyTo?.id,
    );
    setState(() => _replyTo = null);
  }

  Future<void> _sendFile() async {
    final picked = await FilePicker.pickFile();
    if (picked?.path == null) return;
    final file = File(picked!.path!);
    final ext = p.extension(file.path).replaceFirst('.', '');
    final url = await _storage.uploadChatMedia(
      chatId: widget.chat.id,
      file: file,
      contentType: 'application/octet-stream',
      extension: ext.isEmpty ? 'bin' : ext,
    );
    await _chat.sendMessage(chatId: widget.chat.id, type: 'file', mediaUrl: url, text: picked.name);
  }

  Future<void> _sendPhoto() async {
    final cameras = await availableCameras();
    if (!mounted || cameras.isEmpty) return;
    final file = await Navigator.of(context).push<File>(
      MaterialPageRoute(builder: (_) => _ChatCameraPage(cameras: cameras)),
    );
    if (file == null) return;
    final url = await _storage.uploadChatMedia(
      chatId: widget.chat.id,
      file: file,
      contentType: 'image/jpeg',
      extension: 'jpg',
    );
    await _chat.sendMessage(chatId: widget.chat.id, type: 'image', mediaUrl: url, text: 'Photo');
  }

  Future<void> _toggleVoice() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path == null) return;
      final url = await _storage.uploadChatMedia(
        chatId: widget.chat.id,
        file: File(path),
        contentType: 'audio/m4a',
        extension: 'm4a',
      );
      await _chat.sendMessage(chatId: widget.chat.id, type: 'audio', mediaUrl: url, text: 'Voice message');
      return;
    }
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() => _recording = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().user?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.isGroup && widget.chat.name.isNotEmpty ? widget.chat.name : 'Chat'),
      ),
      backgroundColor: AppColors.chatBg,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chat.watchMessages(widget.chat.id),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
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
                        onLongPress: () => setState(() => _replyTo = message),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: mine ? AppColors.outgoing : AppColors.incoming,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _MessageBody(message: message, mine: mine),
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
                  IconButton(onPressed: _sendPhoto, icon: const Icon(Icons.camera_alt_outlined)),
                  IconButton(onPressed: _sendFile, icon: const Icon(Icons.attach_file)),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        filled: true,
                      ),
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
  const _MessageBody({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

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
      default:
        content = Text(message.text);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        content,
        const SizedBox(height: 4),
        Text(
          DateFormat.Hm().format(message.createdAt),
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
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
