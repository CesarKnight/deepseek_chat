import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/command.dart';
import '../../../../core/utils/result.dart';
import '../../../../domain/entities/message.dart';
import '../../../../domain/chat_repository_interface.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({required IChatRepository chatRepository})
    : _chatRepository = chatRepository {
    sendMessage = Command1(_sendMessage);
    loadChatHistory = Command0(_loadChatHistory);
    loadChat = Command1(_loadChat);
    clearHistory = Command0(_clearHistory);
    toggleTts = Command1(_toggleTts);

    // No cargar automáticamente, lo haremos en initChat
     _initSpeech();
  }

  final IChatRepository _chatRepository;
  final FlutterTts _flutterTts = FlutterTts();
  final Uuid _uuid = const Uuid();
  final stt.SpeechToText _speech = stt.SpeechToText();

  late final Command1<void, ChatMessage> sendMessage;
  late final Command0<List<Message>> loadChatHistory;
  late final Command1<List<Message>, String> loadChat;
  late final Command0<bool> clearHistory;
  late final Command1<bool, bool> toggleTts;

  String? _currentChatId;
  bool _isTyping = false;
  bool _ttsEnabled = false;
  bool _isInitialized = false;
    bool _isListening = false;
  String _recognizedText = '';
  List<ChatMessage> _messages = [];
  List<Message> _messagesHistory = [
    Message(
      role: "system",
      content: "Please respond in Spanish language only.",
      createdAt: DateTime.now(),
    ),
  ];

  String? get currentChatId => _currentChatId;
  bool get isTyping => _isTyping;
  bool get ttsEnabled => _ttsEnabled;
  bool get isInitialized => _isInitialized;
    bool get isListening => _isListening;
     String get recognizedText => _recognizedText;
  List<ChatMessage> get messages => _messages;
  List<Message> get messagesHistory => _messagesHistory;
  set isInitialized(bool value) {
    _isInitialized = value;
  }

  final ChatUser currentUser = ChatUser(
    id: '1',
    firstName: 'Cesar',
    lastName: 'Caballero',
  );

  final ChatUser deepseekUser = ChatUser(id: '2', firstName: 'Asistente');

  /// Inicializa el chat con un ID existente o crea uno nuevo
  /// Inicializa el chat con un ID existente o crea uno nuevo
  Future<void> initChat(String? chatId) async {
    if (_isInitialized) return;

    if (chatId != null && chatId.isNotEmpty) {
      // Cargar un chat existente
      await loadChat.execute(chatId);
    } else {
      // Ya fue reiniciado en resetChat(), no necesitamos hacer nada más
    }
    _isInitialized = true;
  }

  void resetChat() {
    _currentChatId = null;
    _messages = [];
    _messagesHistory = [
      Message(
        role: "system",
        content: "Please respond in Spanish language only.",
        createdAt: DateTime.now(),
      ),
    ];
    _isInitialized = false;
    // notifyListeners();
  }

  void setTyping(bool value) {
    _isTyping = value;
    notifyListeners();
  }

  Future<Result<void>> _sendMessage(ChatMessage message) async {
    // Generate a new chat ID if this is a new conversation
    _currentChatId ??= _uuid.v4();

    _messages.insert(0, message);
    final Message messageE = Message(
      role: "user",
      content: message.text,
      createdAt: DateTime.now(),
    );
    _messagesHistory.add(messageE);
    notifyListeners();

    final result = await _chatRepository.sendMessage(messageE, currentChatId!);

    return switch (result) {
      Ok(value: final content) => () {
        final botMessage = ChatMessage(
          user: deepseekUser,
          text: content,
          createdAt: DateTime.now(),
        );

        _messages.insert(0, botMessage);
        _messagesHistory.add(
          Message(
            role: "assistant",
            content: content,
            createdAt: DateTime.now(),
          ),
        );
        notifyListeners();

        if (_ttsEnabled) {
          final plainTextMessage = content.replaceAll(RegExp(r'[^\w\s]+'), '');
          _flutterTts.speak(plainTextMessage);
        }
        return const Ok(null);
      }(),

      Error(error: final e) => Error(e),
    };
  }

  Future<Result<List<Message>>> _loadChatHistory() async {
    final result = await _chatRepository.getChatHistory();

    return switch (result) {
      Ok(value: final history) => () {
        // Ordenar mensajes por fecha de creación (más antiguos primero)
        final sortedHistory = List<Message>.from(history)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        // Convert history items to ChatMessages
        _messages =
            sortedHistory.where((msg) => msg.role != "system").map((msg) {
              return ChatMessage(
                user: msg.role == "user" ? currentUser : deepseekUser,
                text: msg.content,
                createdAt: msg.createdAt,
              );
            }).toList();

        // Add to messages history
        _messagesHistory = [
          Message(
            role: "system",
            content: "Please respond in Spanish language only.",
            createdAt: DateTime.now(),
          ),
          ...sortedHistory,
        ];

        notifyListeners();
        return Ok(history);
      }(),

      Error(error: final e) => Error(e),
    };
  }

  Future<Result<List<Message>>> _loadChat(String chatId) async {
    _currentChatId = chatId;
    final result = await _chatRepository.loadChat(chatId);

    return switch (result) {
      Ok(value: final history) => () {
        // Ordenar mensajes por fecha de creación (más antiguos primero)
        final sortedHistory = List<Message>.from(history)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        // Convert history items to ChatMessages
        _messages =
            sortedHistory
                .where((msg) => msg.role != "system")
                .map((msg) {
                  return ChatMessage(
                    user: msg.role == "user" ? currentUser : deepseekUser,
                    text: msg.content,
                    createdAt: new DateTime.now(),
                  );
                })
                .toList()
                .reversed
                .toList();

        // Add to messages history
        _messagesHistory = [
          Message(
            role: "system",
            content: "Please respond in Spanish language only.",
            createdAt: DateTime.now(),
          ),
          ...sortedHistory,
        ];

        notifyListeners();
        return Ok(history);
      }(),

      Error(error: final e) => Error(e),
    };
  }

  Future<Result<bool>> _clearHistory() async {
    final result = await _chatRepository.clearChatHistory();

    return switch (result) {
      Ok(value: final success) => () {
        if (success) {
          _currentChatId = null;
          _messages = [];
          _messagesHistory = [
            Message(
              role: "system",
              content: "Please respond in Spanish language only.",
              createdAt: DateTime.now(),
            ),
          ];
          notifyListeners();
        }
        return Ok(success);
      }(),

      Error(error: final e) => Error(e),
    };
  }

  Future<Result<bool>> _toggleTts(bool enabled) async {
    final result = await _chatRepository.toggleTts(enabled);

    return switch (result) {
      Ok(value: final success) => () {
        if (success) {
          _ttsEnabled = enabled;
          notifyListeners();
        }
        return Ok(success);
      }(),

      Error(error: final e) => Error(e),
    };
  }

    Future<void> toggleListening(TextEditingController controller) async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;

      // Si tenemos texto reconocido, lo enviamos como mensaje
      if (_recognizedText.isNotEmpty) {
        final message = ChatMessage(
          text: _recognizedText,
          user: currentUser,
          createdAt: DateTime.now(),
        );
        sendMessage.execute(message);
        _recognizedText = '';
      }
    } else {
      _recognizedText = '';
      controller.clear();

      // Comenzar a escuchar
      await _speech.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          controller.text = _recognizedText;
          notifyListeners();
        },
        localeId: 'es_ES', // Usar español de España, puedes cambiarlo por el idioma que necesites
      );

      _isListening = true;
    }

    notifyListeners();
  }


  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (error) {
          _isListening = false;
          notifyListeners();
          print('Error de reconocimiento de voz: $error');
        },
      );
      print('Reconocimiento de voz disponible: $available');
    } catch (e) {
      print('Error al inicializar el reconocimiento de voz: $e');
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    sendMessage.dispose();
    loadChatHistory.dispose();
    loadChat.dispose();
    clearHistory.dispose();
    toggleTts.dispose();
    super.dispose();
  }
}
