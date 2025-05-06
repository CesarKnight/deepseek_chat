import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:deepseek_chat/domain/chat_repository_interface.dart';
import 'package:deepseek_chat/domain/entities/chat_preview.dart';
import '../../domain/entities/message.dart';
import '../../core/utils/result.dart';
import '../services/api_service.dart';

class ChatRepository implements IChatRepository {
  final ApiService _apiService;
  final String _chatListKey = 'chat_list';
  final String _chatPrefix = 'chat_';
  final String _ttsEnabledKey = 'tts_enabled';

  ChatRepository(this._apiService);

  @override
  Future<Result<String>> sendMessage(Message message, String conversationId) async {
    try {
      // Enviar mensaje a la API
      final result = await _apiService.sendMessage(message.content, conversationId);

      return switch (result) {
        Ok(value: final response) => () async {
          // Si la respuesta es exitosa, guardar en caché
          await _saveMessageToCache(message, conversationId);

          // Guardar la respuesta del asistente
          final assistantMessage = Message(
            role: "assistant",
            content: response.answer,
            createdAt: DateTime.now(),
          );
          await _saveMessageToCache(assistantMessage, conversationId);

          // Actualizar preview de la conversación
          await _updateChatPreview(conversationId, message.content, response.answer);

          return Ok(response.answer);
        }(),
        Error(error: final e) => Error(e),
      };
    } catch (e) {
      return Error(Exception('Repository error: $e'));
    }
  }

  /// Guarda un mensaje en la caché bajo una conversación específica
  Future<void> _saveMessageToCache(Message message, String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener los mensajes existentes o crear una lista vacía
      final chatKey = '$_chatPrefix$conversationId';
      final existingChatJson = prefs.getString(chatKey);

      List<Map<String, dynamic>> chatMessages = [];
      if (existingChatJson != null) {
        chatMessages = List<Map<String, dynamic>>.from(
          jsonDecode(existingChatJson) as List,
        );
      }

      // Añadir el nuevo mensaje
      chatMessages.add({
        'role': message.role,
        'content': message.content,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Guardar la lista actualizada
      await prefs.setString(chatKey, jsonEncode(chatMessages));
    } catch (e) {
      print('Error saving message to cache: $e');
    }
  }

  /// Actualiza la vista previa de un chat en la lista de chats
  Future<void> _updateChatPreview(String conversationId, String userMessage, String assistantResponse) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener la lista de chats
      final chatListJson = prefs.getString(_chatListKey);
      List<Map<String, dynamic>> chatList = [];

      if (chatListJson != null) {
        chatList = List<Map<String, dynamic>>.from(
          jsonDecode(chatListJson) as List,
        );
      }

      // Buscar si ya existe una vista previa para este chat
      final now = DateTime.now().toIso8601String();
      final existingChatIndex = chatList.indexWhere((chat) => chat['id'] == conversationId);

      if (existingChatIndex >= 0) {
        // Actualizar chat existente
        chatList[existingChatIndex]['updatedAt'] = now;
        chatList[existingChatIndex]['messageCount'] = (chatList[existingChatIndex]['messageCount'] as int) + 2; // Usuario + Asistente
        chatList[existingChatIndex]['lastMessage'] = assistantResponse;
      } else {
        // Crear un nuevo chat
        chatList.add({
          'id': conversationId,
          'title': userMessage.length > 30 ? '${userMessage.substring(0, 30)}...' : userMessage,
          'lastMessage': assistantResponse,
          'createdAt': now,
          'updatedAt': now,
          'messageCount': 2, // Usuario + Asistente
        });
      }

      // Guardar la lista actualizada
      await prefs.setString(_chatListKey, jsonEncode(chatList));
    } catch (e) {
      print('Error updating chat preview: $e');
    }
  }

  @override
  Future<Result<List<Message>>> getChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener la lista de chats
      final chatListJson = prefs.getString(_chatListKey);
      if (chatListJson == null || jsonDecode(chatListJson).isEmpty) {
        return const Ok([]);
      }

      // Obtener el chat más reciente
      final chatList = List<Map<String, dynamic>>.from(
        jsonDecode(chatListJson) as List,
      );

      // Ordenar por fecha de actualización (más reciente primero)
      chatList.sort((a, b) =>
        DateTime.parse(b['updatedAt'].toString()).compareTo(
          DateTime.parse(a['updatedAt'].toString())
        )
      );

      // Obtener los mensajes del chat más reciente
      final mostRecentChatId = chatList.first['id'];
      return await loadChat(mostRecentChatId);

    } catch (e) {
      return Error(Exception('Failed to get chat history: $e'));
    }
  }

  @override
  Future<Result<List<Message>>> loadChat(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener los mensajes del chat
      final chatKey = '$_chatPrefix$chatId';
      final chatJson = prefs.getString(chatKey);

      if (chatJson == null) {
        return const Ok([]);
      }

      // Convertir JSON a lista de mensajes
      final chatData = List<Map<String, dynamic>>.from(
        jsonDecode(chatJson) as List,
      );

      final messages = chatData.map((msgData) => Message(
        role: msgData['role'],
        content: msgData['content'],
        createdAt: DateTime.parse(msgData['timestamp']),
      )).toList();

      return Ok(messages);
    } catch (e) {
      return Error(Exception('Failed to load chat: $e'));
    }
  }

  @override
  Future<Result<List<ChatPreview>>> getChatList() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener la lista de chats
      final chatListJson = prefs.getString(_chatListKey);

      if (chatListJson == null) {
        return const Ok([]);
      }

      // Convertir JSON a lista de vistas previas
      final chatListData = List<Map<String, dynamic>>.from(
        jsonDecode(chatListJson) as List,
      );

      // Ordenar por fecha de actualización (más reciente primero)
      chatListData.sort((a, b) =>
        DateTime.parse(b['updatedAt'].toString()).compareTo(
          DateTime.parse(a['updatedAt'].toString())
        )
      );

      final chatPreviews = chatListData.map((chatData) => ChatPreview(
        id: chatData['id'],
        title: chatData['title'],
        lastMessage: chatData['lastMessage'],
        createdAt: DateTime.parse(chatData['createdAt']),
        updatedAt: DateTime.parse(chatData['updatedAt']),
        messageCount: chatData['messageCount'],
      )).toList();

      return Ok(chatPreviews);
    } catch (e) {
      return Error(Exception('Failed to get chat list: $e'));
    }
  }

  @override
  Future<Result<bool>> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener la lista de chats
      final chatListJson = prefs.getString(_chatListKey);
      if (chatListJson == null) {
        return const Ok(true);
      }

      // Convertir JSON a lista de chats
      final chatList = List<Map<String, dynamic>>.from(
        jsonDecode(chatListJson) as List,
      );

      // Eliminar todos los mensajes de los chats
      for (final chat in chatList) {
        final chatId = chat['id'];
        final chatKey = '$_chatPrefix$chatId';
        await prefs.remove(chatKey);
      }

      // Eliminar la lista de chats
      await prefs.remove(_chatListKey);

      return const Ok(true);
    } catch (e) {
      return Error(Exception('Failed to clear chat history: $e'));
    }
  }

  @override
  Future<Result<bool>> deleteChat(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener la lista de chats
      final chatListJson = prefs.getString(_chatListKey);
      if (chatListJson == null) {
        return const Ok(false);
      }

      // Convertir JSON a lista de chats
      final chatList = List<Map<String, dynamic>>.from(
        jsonDecode(chatListJson) as List,
      );

      // Buscar el chat a eliminar
      final chatIndex = chatList.indexWhere((chat) => chat['id'] == chatId);
      if (chatIndex < 0) {
        return const Ok(false);
      }

      // Guardar chat en caché temporalmente para posible restauración
      final deletedChat = chatList[chatIndex];
      await prefs.setString('deleted_chat_$chatId', jsonEncode(deletedChat));

      // Eliminar el chat de la lista
      chatList.removeAt(chatIndex);
      await prefs.setString(_chatListKey, jsonEncode(chatList));

      // No eliminar los mensajes por si se restaura

      return const Ok(true);
    } catch (e) {
      return Error(Exception('Failed to delete chat: $e'));
    }
  }

  @override
  Future<Result<ChatPreview?>> restoreChat(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener el chat eliminado
      final deletedChatJson = prefs.getString('deleted_chat_$chatId');
      if (deletedChatJson == null) {
        return const Ok(null);
      }

      // Obtener la lista actual de chats
      final chatListJson = prefs.getString(_chatListKey);
      List<Map<String, dynamic>> chatList = [];

      if (chatListJson != null) {
        chatList = List<Map<String, dynamic>>.from(
          jsonDecode(chatListJson) as List,
        );
      }

      // Restaurar el chat eliminado
      final deletedChat = jsonDecode(deletedChatJson) as Map<String, dynamic>;
      chatList.add(deletedChat);

      // Guardar la lista actualizada
      await prefs.setString(_chatListKey, jsonEncode(chatList));

      // Eliminar el chat de la caché de eliminados
      await prefs.remove('deleted_chat_$chatId');

      return Ok(ChatPreview(
        id: deletedChat['id'],
        title: deletedChat['title'],
        lastMessage: deletedChat['lastMessage'],
        createdAt: DateTime.parse(deletedChat['createdAt']),
        updatedAt: DateTime.parse(deletedChat['updatedAt']),
        messageCount: deletedChat['messageCount'],
      ));
    } catch (e) {
      return Error(Exception('Failed to restore chat: $e'));
    }
  }

  @override
  Future<Result<bool>> toggleTts(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_ttsEnabledKey, enabled);
      return Ok(enabled);
    } catch (e) {
      return Error(Exception('Failed to toggle TTS: $e'));
    }
  }
}