import 'dart:convert';
import '../../../core/utils/result.dart';
import '../../../domain/entities/message.dart';
import '../../../data/models/chat_response_model.dart';
import 'api_client.dart';

class ApiService {
  final ApiClient _apiClient;

  ApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Sends a list of messages to the API and returns a ChatResponseModel
  Future<Result<ChatResponseModel>> sendMessage(String message, String conversationId) async {
    try {
      final response = await _apiClient.post(
        endpoint: '/api/chat',
        body: jsonEncode({
          "query": message,
          "chat_id": conversationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Ok(ChatResponseModel.fromJson(data));
      } else {
        return Error(Exception('Failed to get response: ${response.statusCode}'));
      }
    } catch (e) {
      return Error(Exception('API Service error: $e'));
    }
  }

  /// Retrieves user information from the API
  Future<Result<Map<String, dynamic>>> getUserProfile() async {
    try {
      final response = await _apiClient.get(endpoint: '/user/profile');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Ok(data);
      } else {
        return Error(Exception('Failed to get user profile: ${response.statusCode}'));
      }
    } catch (e) {
      return Error(Exception('API Service error: $e'));
    }
  }

  /// Updates settings in the API
  Future<Result<bool>> updateSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _apiClient.put(
        endpoint: '/user/settings',
        body: jsonEncode(settings),
      );

      if (response.statusCode == 200) {
        return const Ok(true);
      } else {
        return Error(Exception('Failed to update settings: ${response.statusCode}'));
      }
    } catch (e) {
      return Error(Exception('API Service error: $e'));
    }
  }
}