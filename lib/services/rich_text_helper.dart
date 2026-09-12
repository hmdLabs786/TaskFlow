import 'dart:convert';

class RichTextHelper {
  static bool isRichText(String? note) {
    if (note == null || note.isEmpty) return false;
    return note.startsWith('[');
  }

  static String extractPlainText(String? note) {
    if (note == null || note.isEmpty) return '';
    if (!isRichText(note)) return note;
    try {
      final ops = jsonDecode(note) as List;
      final buffer = StringBuffer();
      for (final op in ops) {
        final insert = op['insert'];
        if (insert is String) buffer.write(insert);
      }
      return buffer.toString();
    } catch (_) {
      return note;
    }
  }
}