import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/llm_service.dart';
import '../utils/device_id.dart';

class ChatProvider with ChangeNotifier {
  LlmService? _llmService;
  final Uuid _uuid = Uuid();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  int _pregnancyWeek = 1;
  bool _isInitialized = false;
  Exception? _initializationError;
  String _deviceId = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final bool _dotEnvInitialized;
  final bool _firebaseInitialized;

  List<ChatMessage> get messages => _messages.take(50).toList();
  bool get isLoading => _isLoading;
  int get pregnancyWeek => _pregnancyWeek;
  bool get isInitialized => _isInitialized;
  Exception? get initializationError => _initializationError;

  ChatProvider({required bool dotEnvInitialized, required bool firebaseInitialized})
      : _dotEnvInitialized = dotEnvInitialized,
        _firebaseInitialized = firebaseInitialized {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      debugPrint('Starting ChatProvider initialization');
      _deviceId = await getDeviceId();
      if (_firebaseInitialized) {
        _firestore.settings = const Settings(
          host: 'localhost:8080',
          sslEnabled: false,
          persistenceEnabled: false,
        );
      }
      if (_dotEnvInitialized) {
        _llmService = LlmService();
      } else {
        throw Exception('API key not initialized');
      }
      final prefs = await SharedPreferences.getInstance();
      _pregnancyWeek = prefs.getInt('pregnancyWeek') ?? 1;
      debugPrint('Loaded pregnancy week: $_pregnancyWeek');
      await _loadMessages();
      await _syncLocalToFirestore();
      if (_messages.isEmpty) {
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          text:
              "Hello! I'm your prenatal care assistant. I'm here to help with information about your pregnancy (week $_pregnancyWeek). How can I help you today?",
          role: MessageRole.bot,
          timestamp: DateTime.now(),
        ));
        if (_firebaseInitialized) {
          await _saveMessageToFirestore(_messages.last);
        }
      }
      _isInitialized = true;
      _initializationError = null;
    } catch (e, stackTrace) {
      debugPrint('Error initializing: $e\n$stackTrace');
      _initializationError = Exception('Failed to initialize assistant: $e');
      _isInitialized = true;
      _messages = [
        ChatMessage(
          id: _uuid.v4(),
          text: _dotEnvInitialized
              ? "Failed to initialize assistant. Please try again."
              : "API key missing. Please contact support.",
          role: MessageRole.bot,
          timestamp: DateTime.now(),
        ),
      ];
    }
    debugPrint('ChatProvider initialization complete, isInitialized: $_isInitialized');
    notifyListeners();
  }

  Future<void> retryInitialization() async {
    _isInitialized = false;
    _initializationError = null;
    _messages = [];
    notifyListeners();
    await _initialize();
  }

  Future<void> _loadMessages() async {
    try {
      if (_firebaseInitialized) {
        final snapshot = await _firestore
            .collection('users')
            .doc(_deviceId)
            .collection('chats')
            .orderBy('timestamp', descending: false)
            .get();
        _messages = snapshot.docs.map((doc) => ChatMessage.fromJson(doc.data(), doc.id)).toList();
      }

      final prefs = await SharedPreferences.getInstance();
      final storedMessages = prefs.getStringList('chat_history') ?? [];
      if (_messages.isEmpty && storedMessages.isNotEmpty) {
        _messages = storedMessages.map((m) {
          final parts = m.split('|');
          return ChatMessage(
            id: _uuid.v4(),
            text: parts[0],
            role: parts[1] == 'true' ? MessageRole.user : MessageRole.bot,
            timestamp: DateTime.parse(parts[2]),
          );
        }).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> _saveMessageToFirestore(ChatMessage message) async {
    if (!_firebaseInitialized) return;
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_deviceId)
          .collection('chats')
          .add(message.toJson());
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messages[index] = ChatMessage(
          id: docRef.id,
          text: message.text,
          role: message.role,
          timestamp: message.timestamp,
        );
      }
      final prefs = await SharedPreferences.getInstance();
      final storedMessages = prefs.getStringList('chat_history') ?? [];
      storedMessages.add(
        '${message.text}|${message.role == MessageRole.user}|${message.timestamp.toIso8601String()}${message.role == MessageRole.bot ? '|${message.text}' : ''}',
      );
      await prefs.setStringList('chat_history', storedMessages);
    } catch (e) {
      debugPrint('Error saving message to Firestore: $e');
    }
  }

  Future<void> _syncLocalToFirestore() async {
    if (!_firebaseInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final chats = prefs.getStringList('chat_history') ?? [];
      for (var chat in chats) {
        final parts = chat.split('|');
        await _firestore
            .collection('users')
            .doc(_deviceId)
            .collection('chats')
            .add({
          'message': parts[0],
          'isUser': parts[1] == 'true',
          'timestamp': Timestamp.fromDate(DateTime.parse(parts[2])),
          'context': parts.length > 3 ? parts[3] : null,
        });
      }
      await prefs.setStringList('chat_history', []);
    } catch (e) {
      debugPrint('Error syncing chats to Firestore: $e');
    }
  }

  Future<void> updatePregnancyWeek(int week) async {
    try {
      _pregnancyWeek = week;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pregnancyWeek', week);
      debugPrint('Updated pregnancy week: $week');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error updating pregnancy week: $e\n$stackTrace');
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
      if (_llmService == null || !_dotEnvInitialized) {
        throw Exception('LlmService not initialized or API key missing');
      }
      if (_firebaseInitialized) {
        await _saveMessageToFirestore(userMessage);
      }
      final response = await _llmService!.sendMessage(text, _pregnancyWeek);
      final botMessage = ChatMessage(
        id: _uuid.v4(),
        text: response,
        role: MessageRole.bot,
        timestamp: DateTime.now(),
      );
      _messages.add(botMessage);
      if (_firebaseInitialized) {
        await _saveMessageToFirestore(botMessage);
      }
    } catch (e, stackTrace) {
      debugPrint('Error sending message: $e\n$stackTrace');
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        text: _dotEnvInitialized
            ? "I'm sorry, I couldn't process your request. Please try again later."
            : "API key missing. Please contact support.",
        role: MessageRole.bot,
        timestamp: DateTime.now(),
      ));
      if (_firebaseInitialized) {
        await _saveMessageToFirestore(_messages.last);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    try {
      if (_firebaseInitialized) {
        final snapshot = await _firestore
            .collection('users')
            .doc(_deviceId)
            .collection('chats')
            .get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('chat_history', []);
      _messages = [
        ChatMessage(
          id: _uuid.v4(),
          text:
              "Hello! I'm your prenatal care assistant. I'm here to help with information about your pregnancy (week $_pregnancyWeek). How can I help you today?",
          role: MessageRole.bot,
          timestamp: DateTime.now(),
        ),
      ];
      if (_firebaseInitialized) {
        await _saveMessageToFirestore(_messages.last);
      }
      debugPrint('Chat history cleared');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error clearing chat: $e\n$stackTrace');
    }
  }
}