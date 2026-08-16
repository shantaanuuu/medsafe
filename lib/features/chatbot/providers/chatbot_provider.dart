import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../services/chat_storage_service.dart';
import '../chatbot_system_prompt.dart';

// Tracks current dynamic user screen context
class CurrentScreenNotifier extends Notifier<String> {
  @override
  String build() {
    return 'Home Screen';
  }

  void setScreen(String name) {
    state = name;
  }
}

final currentScreenProvider = NotifierProvider<CurrentScreenNotifier, String>(() {
  return CurrentScreenNotifier();
});

// Loading state for chatbot responses
class ChatLoadingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setLoading(bool loading) {
    state = loading;
  }
}

final chatLoadingProvider = NotifierProvider<ChatLoadingNotifier, bool>(() {
  return ChatLoadingNotifier();
});

// Storage service provider
final chatStorageProvider = Provider<ChatStorageService>((ref) => ChatStorageService());

// Chat notifier managing messages list and backend operations using modern Notifier
class ChatHistoryNotifier extends Notifier<List<ChatMessage>> {
  late final ChatStorageService _storage;

  @override
  List<ChatMessage> build() {
    _storage = ref.watch(chatStorageProvider);
    _loadFromStorage();
    return [];
  }

  Future<void> _loadFromStorage() async {
    final loaded = await _storage.loadHistory();
    state = loaded;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Append user message immediately
    state = [...state, userMessage];
    await _storage.saveHistory(state);

    ref.read(chatLoadingProvider.notifier).setLoading(true);

    try {
      // Build history payload for Gemini
      final List<Map<String, String>> historyPayload = state.take(state.length - 1).map((msg) {
        return {
          'role': msg.isUser ? 'user' : 'model',
          'text': msg.text,
        };
      }).toList();

      final currentContext = ref.read(currentScreenProvider);

      const String baseUrl = String.fromEnvironment(
        'BACKEND_BASE_URL',
        defaultValue: 'http://10.0.2.2:5000',
      );

      final uri = Uri.parse('$baseUrl/api/chatbot');
      final response = await http.post(
        uri,
        headers: const <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'system_prompt': chatbotSystemPrompt,
          'message': text,
          'history': historyPayload,
          'context': currentContext,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Chatbot service error (status ${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        throw Exception('Invalid chatbot response format');
      }

      final reply = decoded['reply'] as String? ?? 'No response';
      
      final assistantMessage = ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = [...state, assistantMessage];
      await _storage.saveHistory(state);
    } catch (e) {
      debugPrint("CHATBOT_PROVIDER ERROR: $e");
      final errorMessage = ChatMessage(
        text: "I'm having trouble connecting right now. Please make sure the MedSafe backend is running.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = [...state, errorMessage];
    } finally {
      ref.read(chatLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> clearHistory() async {
    state = [];
    await _storage.clearHistory();
  }
}

// Provider for chat history state
final chatHistoryProvider = NotifierProvider<ChatHistoryNotifier, List<ChatMessage>>(() {
  return ChatHistoryNotifier();
});
