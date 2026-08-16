import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatStorageService {
  static const String _storageKey = 'medsafe_chatbot_history';

  Future<List<ChatMessage>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? encoded = prefs.getStringList(_storageKey);
      if (encoded == null) return [];

      return encoded
          .map((item) => ChatMessage.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<ChatMessage> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> encoded =
          history.map((msg) => jsonEncode(msg.toJson())).toList();
      await prefs.setStringList(_storageKey, encoded);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
