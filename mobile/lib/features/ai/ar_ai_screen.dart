import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/chat.dart';
import '../../providers/auth_controller.dart';
import '../../services/ai_service.dart';
import '../../services/chat_service.dart';
import '../../services/workplace_service.dart';

class ArAiScreen extends StatefulWidget {
  const ArAiScreen({super.key, this.chat});

  final ChatThread? chat;

  @override
  State<ArAiScreen> createState() => _ArAiScreenState();
}

class _ArAiScreenState extends State<ArAiScreen> {
  final _input = TextEditingController();
  final _ai = ArAiService();
  final _chat = ChatService();
  String _output = 'Ask AR AI to summarize, translate, rewrite, extract tasks, or search.';
  bool _busy = false;
  String _language = 'Arabic';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<List<ChatMessage>> _messages() async {
    if (widget.chat != null) return _chat.latestMessages(widget.chat!.id);
    final chats = await _chat.watchChats().first;
    if (chats.isEmpty) return const [];
    return _chat.latestMessages(chats.first.id);
  }

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final result = await action();
      setState(() => _output = result);
    } catch (error) {
      setState(() => _output = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('AR AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _input,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Ask, write, translate, or create a task…'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AiChip(label: 'Summarize', onTap: () => _run(() async => _ai.summarize(await _messages()))),
              _AiChip(label: 'Professional', onTap: () => _run(() async => _ai.professional(_input.text))),
              _AiChip(
                label: 'Translate',
                onTap: () => _run(() async {
                  final fallback = await _messages();
                  final source = _input.text.trim().isEmpty ? (fallback.isEmpty ? '' : fallback.first.text) : _input.text;
                  return _ai.translate(source, _language);
                }),
              ),
              _AiChip(label: 'Extract tasks', onTap: () => _run(() async => _ai.extractTasks(_input.text.isEmpty ? (await _messages()).map((m) => m.text).join('\n') : _input.text))),
              _AiChip(
                label: 'Create task',
                onTap: () => _run(() async {
                  if (profile == null) return 'Sign in first.';
                  final title = _input.text.trim().isEmpty ? 'Follow up from chat' : _input.text.trim();
                  await WorkplaceService().createTask(profile: profile, title: title, assigneeName: 'Ahmed');
                  return 'TASK CREATED\n\n$title\nAssigned to: Ahmed\nPriority: High\nStatus: Pending';
                }),
              ),
              _AiChip(
                label: 'Search',
                onTap: () => _run(() async {
                  final query = _input.text.trim().toLowerCase();
                  if (query.isEmpty) return 'Type a search, for example: Building 4';
                  final messages = await _messages();
                  final hits = messages.where((m) => m.text.toLowerCase().contains(query)).map((m) => '• ${m.text}').take(8);
                  return hits.isEmpty ? 'No matching messages.' : 'Found:\n${hits.join('\n')}';
                }),
              ),
              _AiChip(
                label: 'Meeting summary',
                onTap: () => _run(() async {
                  final summary = _ai.summarize(await _messages());
                  return 'MEETING SUMMARY\n\n$summary\n\nRecording consent: only transcribe meetings when every participant agrees.';
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: const InputDecoration(labelText: 'Translate into'),
            items: const ['Arabic', 'Malayalam', 'Hindi', 'Tamil', 'Urdu', 'English']
                .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                .toList(),
            onChanged: (value) => setState(() => _language = value ?? 'Arabic'),
          ),
          const SizedBox(height: 16),
          if (_busy) const Center(child: CircularProgressIndicator()),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Text(_output, style: const TextStyle(height: 1.4)),
          ),
          const SizedBox(height: 16),
          if (_output.isNotEmpty)
            PrimaryButton(
              label: 'Send to chat',
              onPressed: widget.chat == null
                  ? null
                  : () async {
                      await _chat.sendMessage(chatId: widget.chat!.id, type: 'text', text: _output);
                      if (context.mounted) Navigator.pop(context);
                    },
            ),
        ],
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}
