import 'package:flutter/material.dart';
import 'package:pregnancy_chatbot/models/chat_message.dart';
import 'package:pregnancy_chatbot/services/llm_service.dart';
import 'package:pregnancy_chatbot/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class ChatProvider with ChangeNotifier {
  LlmService? _llmService;
  final StorageService _storageService = StorageService();
  final Uuid _uuid = Uuid();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  int _pregnancyWeek = 1;
  bool _isInitialized = false;
  Exception? _initializationError;

  List<ChatMessage> get messages => _messages.take(50).toList();
  bool get isLoading => _isLoading;
  int get pregnancyWeek => _pregnancyWeek;
  bool get isInitialized => _isInitialized;
  Exception? get initializationError => _initializationError;

  ChatProvider() {
    try {
      _llmService = LlmService();
      _initializeChat();
    } catch (e, stackTrace) {
      print('Error initializing LlmService: $e\n$stackTrace');
      _initializationError = Exception('Failed to initialize assistant: $e');
      _isInitialized = true;
      _messages = [
        ChatMessage(
          id: _uuid.v4(),
          text: "Failed to initialize assistant. Please try again.",
          role: MessageRole.bot,
          timestamp: DateTime.now(),
        ),
      ];
      notifyListeners();
    }
  }

  Future<void> _initializeChat() async {
    try {
      print('Starting ChatProvider initialization');
      _pregnancyWeek = await _storageService.loadPregnancyWeek();
      print('Loaded pregnancy week: $_pregnancyWeek');
      _messages = await _storageService.loadChatHistory();
      print('Loaded ${_messages.length} messages');
      if (_messages.isEmpty) {
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          text:
              "Hello! I'm your prenatal care assistant. I'm here to help with information about your pregnancy (week $_pregnancyWeek). How can I help you today?",
          role: MessageRole.bot,
          timestamp: DateTime.now(),
        ));
      }
      _isInitialized = true;
      _initializationError = null;
    } catch (e, stackTrace) {
      print('Error initializing chat: $e\n$stackTrace');
      _initializationError = e is Exception ? e : Exception('Initialization failed: $e');
      _isInitialized = true;
      _messages = [
        ChatMessage(
          id: _uuid.v4(),
          text: "Failed to load chat history. Please try again later.",
          role: MessageRole.bot,
          timestamp: DateTime.now(),
        ),
      ];
    }
    print('ChatProvider initialization complete, isInitialized: $_isInitialized');
    notifyListeners();
  }

  Future<void> retryInitialization() async {
    _isInitialized = false;
    _initializationError = null;
    _messages = [];
    notifyListeners();
    try {
      _llmService = LlmService();
      await _initializeChat();
    } catch (e, stackTrace) {
      print('Error retrying initialization: $e\n$stackTrace');
      _initializationError = Exception('Retry failed: $e');
      _isInitialized = true;
      _messages = [
        ChatMessage(
          id: _uuid.v4(),
          text: "Failed to initialize assistant. Please try again.",
          role: MessageRole.bot,
          timestamp: DateTime.now(),
        ),
      ];
      notifyListeners();
    }
  }

  Future<void> updatePregnancyWeek(int week) async {
    try {
      _pregnancyWeek = week;
      await _storageService.savePregnancyWeek(week);
      print('Updated pregnancy week: $week');
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error updating pregnancy week: $e\n$stackTrace');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      text: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    try {
      if (_llmService == null) {
        throw Exception('LlmService not initialized');
      }
      final response = await _llmService!.sendMessage(text, _pregnancyWeek);
      final truncatedResponse = response.length > 500 ? '${response.substring(0, 500)}...' : response;
      final botMessage = ChatMessage(
        id: _uuid.v4(),
        text: truncatedResponse,
        role: MessageRole.bot,
        timestamp: DateTime.now(),
      );
      _messages.add(botMessage);
      await _storageService.saveChatHistory(_messages);
    } catch (e, stackTrace) {
      print('Error sending message: $e\n$stackTrace');
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: "I'm sorry, I couldn't process your request. Please try again later.",
        role: MessageRole.bot,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    try {
      _messages = [
        ChatMessage(
          id: _uuid.v4(),
          text:
              "Hello! I'm your prenatal care assistant. I'm here to help with information about your pregnancy (week $_pregnancyWeek). How can I help you today?",
          role: MessageRole.bot,
          timestamp: DateTime.now(),
        )
      ];
      await _storageService.saveChatHistory(_messages);
      print('Chat history cleared');
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error clearing chat: $e\n$stackTrace');
    }
  }
}