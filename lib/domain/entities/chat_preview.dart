class ChatPreview {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  ChatPreview({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });
}