import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class StorageService {
  static const String _chatHistoryKey = 'chat_history';
  static const String _pregnancyWeekKey = 'pregnancy_week';

  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final limitedMessages = messages.take(50).toList();
      final jsonData = limitedMessages.map((msg) => {
            'id': msg.id,
            'text': msg.text,
            'role': msg.role == MessageRole.user ? 'user' : 'bot',
            'timestamp': msg.timestamp.toIso8601String(),
          }).toList();
      await prefs.setString(_chatHistoryKey, jsonEncode(jsonData));
      print('Saved ${limitedMessages.length} messages to storage');
    } catch (e, stackTrace) {
      print('Error saving chat history: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<List<ChatMessage>> loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_chatHistoryKey);
      if (jsonString == null || jsonString.isEmpty) {
        print('No chat history found in storage');
        return [];
      }
      final jsonData = jsonDecode(jsonString);
      if (jsonData is! List) {
        print('Invalid chat history format: not a list');
        return [];
      }
      final messages = jsonData.map((item) {
        if (item is! Map<String, dynamic>) {
          print('Invalid message format: $item');
          return null;
        }
        try {
          return ChatMessage(
            id: item['id']?.toString() ?? '',
            text: item['text']?.toString() ?? '',
            role: item['role'] == 'user' ? MessageRole.user : MessageRole.bot,
            timestamp: DateTime.tryParse(item['timestamp']?.toString() ?? '') ?? DateTime.now(),
          );
        } catch (e) {
          print('Error parsing message: $item, error: $e');
          return null;
        }
      }).where((msg) => msg != null).cast<ChatMessage>().toList();
      print('Loaded ${messages.length} messages from storage');
      return messages;
    } catch (e, stackTrace) {
      print('Error loading chat history: $e\n$stackTrace');
      return [];
    }
  }

  Future<void> savePregnancyWeek(int week) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_pregnancyWeekKey, week);
      print('Saved pregnancy week: $week');
    } catch (e, stackTrace) {
      print('Error saving pregnancy week: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<int> loadPregnancyWeek() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final week = prefs.getInt(_pregnancyWeekKey) ?? 1;
      print('Loaded pregnancy week: $week');
      return week;
    } catch (e, stackTrace) {
      print('Error loading pregnancy week: $e\n$stackTrace');
      return 1;
    }
  }
}