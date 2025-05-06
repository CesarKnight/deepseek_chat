import 'package:deepseek_chat/domain/entities/chat_preview.dart';
import 'package:deepseek_chat/domain/entities/message.dart';

import '../../core/utils/result.dart';

abstract class IChatRepository {
  Future<Result<String>> sendMessage(Message messages, String conversationID);
   Future<Result<List<Message>>> getChatHistory();

  /// Loads a specific chat by ID
  Future<Result<List<Message>>> loadChat(String chatId);

  /// Clears chat history
  Future<Result<bool>> clearChatHistory();

  /// Toggles text-to-speech
  Future<Result<bool>> toggleTts(bool enabled);

  /// Gets list of all chats
  Future<Result<List<ChatPreview>>> getChatList();

  /// Deletes a chat by ID
  Future<Result<bool>> deleteChat(String chatId);

  /// Restores a previously deleted chat
  Future<Result<ChatPreview?>> restoreChat(String chatId);
}