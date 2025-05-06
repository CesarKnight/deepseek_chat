class ChatResponseModel {
  final String query;
  final String chatId;
  final String answer;

  ChatResponseModel({
    required this.query,
    required this.chatId,
    required this.answer,
  });

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) {
    return ChatResponseModel(
      query: json['query'],
      chatId: json['chat_id'],
      answer: json['respuesta'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'chat_id': chatId,
      'respuesta': answer,
    };
  }
}