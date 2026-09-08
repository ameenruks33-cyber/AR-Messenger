import '../models/chat.dart';

class ArAiService {
  String summarize(List<ChatMessage> messages) {
    final texts = messages
        .where((m) => !m.deleted && m.text.trim().isNotEmpty && m.type == 'text')
        .map((m) => m.text.trim())
        .take(40)
        .toList()
        .reversed
        .toList();
    if (texts.isEmpty) return 'No text messages to summarize yet.';
    final bullets = <String>[];
    for (final text in texts) {
      if (_looksLikeDecision(text) || text.length > 24) {
        bullets.add('• ${_clip(text, 90)}');
      }
      if (bullets.length >= 6) break;
    }
    if (bullets.isEmpty) {
      bullets.addAll(texts.take(4).map((t) => '• ${_clip(t, 90)}'));
    }
    return 'Today\'s discussion:\n${bullets.join('\n')}';
  }

  String professional(String text) {
    var out = text.trim();
    if (out.isEmpty) return out;
    out = out.replaceAll(RegExp(r'\s+'), ' ');
    if (!out.endsWith('.') && !out.endsWith('!') && !out.endsWith('?')) out = '$out.';
    return 'Please note: ${out[0].toUpperCase()}${out.substring(1)}';
  }

  String extractTasks(String text) {
    final lines = <String>[];
    for (final chunk in text.split(RegExp(r'[.\n]'))) {
      final value = chunk.trim();
      if (value.toLowerCase().contains('please') ||
          value.toLowerCase().contains('check') ||
          value.toLowerCase().contains('assign') ||
          value.toLowerCase().contains('repair') ||
          value.toLowerCase().contains('submit')) {
        lines.add('• $value');
      }
    }
    return lines.isEmpty ? 'No clear tasks found. Try a sentence like "Please check Building 4 AC."' : 'Tasks:\n${lines.join('\n')}';
  }

  String translate(String text, String language) {
    const table = {
      'Arabic': {
        'please come to the office at 9': 'يرجى الحضور إلى المكتب الساعة 9',
        'good morning': 'صباح الخير',
        'thank you': 'شكراً',
        'meeting at 3 pm': 'اجتماع الساعة 3 مساءً',
      },
      'Malayalam': {
        'please come to the office at 9': '9 മണിക്ക് ഓഫീസിലേക്ക് വരിക.',
        'good morning': 'സുപ്രഭാതം',
        'thank you': 'നന്ദി',
      },
      'Hindi': {
        'please come to the office at 9': 'कृपया सुबह 9 बजे कार्यालय आएँ।',
        'good morning': 'सुप्रभात',
        'thank you': 'धन्यवाद',
      },
      'Tamil': {
        'good morning': 'காலை வணக்கம்',
        'thank you': 'நன்றி',
      },
      'Urdu': {
        'good morning': 'صبح بخیر',
        'thank you': 'شکریہ',
      },
    };
    final lang = table[language];
    if (lang == null) return text;
    final key = text.trim().toLowerCase();
    return lang[key] ?? '$text\n\n[$language] ${_clip(text, 120)}';
  }

  String _clip(String value, int max) => value.length <= max ? value : '${value.substring(0, max)}…';

  bool _looksLikeDecision(String text) {
    final lower = text.toLowerCase();
    return lower.contains('meeting') ||
        lower.contains('tomorrow') ||
        lower.contains('assign') ||
        lower.contains('inspect') ||
        lower.contains('repair') ||
        lower.contains('office');
  }
}
