import 'package:deepseek_chat/core/utils/command.dart';
import 'package:deepseek_chat/domain/chat_repository_interface.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/result.dart';
import '../../../../../domain/entities/chat_preview.dart';

class ChatListViewModel extends ChangeNotifier {
  ChatListViewModel({
    required IChatRepository chatRepository,
  }) : _chatRepository = chatRepository {
    loadChatList = Command0(_loadChatList);
    deleteChat = Command1(_deleteChat);
    restoreChat = Command1(_restoreChat);
  }

  final IChatRepository _chatRepository;

  late final Command0<List<ChatPreview>> loadChatList;
  late final Command1<void, String> deleteChat;
  late final Command1<void, String> restoreChat;

  List<ChatPreview> _chats = [];
  List<ChatPreview> _filteredChats = [];

  List<ChatPreview> get chats => _chats;
  List<ChatPreview> get filteredChats => _filteredChats;

  void filterChats(String query) {
    if (query.isEmpty) {
      _filteredChats = _chats;
    } else {
      _filteredChats = _chats.where((chat) {
        return chat.title.toLowerCase().contains(query.toLowerCase()) ||
               chat.lastMessage.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  Future<Result<List<ChatPreview>>> _loadChatList() async {
    final result = await _chatRepository.getChatList();

    return switch (result) {
      Ok(value: final chatList) => () {
          _chats = chatList;
          _filteredChats = chatList;
          notifyListeners();
          return Ok(chatList);
        }(),

      Error(error: final e) => Error(e),
    };
  }

  Future<Result<void>> _deleteChat(String chatId) async {
    final result = await _chatRepository.deleteChat(chatId);

    return switch (result) {
      Ok(value: final success) => () {
          if (success) {
            _chats.removeWhere((chat) => chat.id == chatId);
            _filteredChats.removeWhere((chat) => chat.id == chatId);
            notifyListeners();
          }
          return const Ok(null);
        }(),

      Error(error: final e) => Error(e),
    };
  }

  Future<Result<void>> _restoreChat(String chatId) async {
    final result = await _chatRepository.restoreChat(chatId);

    return switch (result) {
      Ok(value: final restoredChat) => () {
          if (restoredChat != null) {
            _chats.add(restoredChat);
            _filteredChats = _chats;
            notifyListeners();
          }
          return const Ok(null);
        }(),

      Error(error: final e) => Error(e),
    };
  }

  @override
  void dispose() {
    loadChatList.dispose();
    deleteChat.dispose();
    restoreChat.dispose();
    super.dispose();
  }
}