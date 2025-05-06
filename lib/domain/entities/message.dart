class Message {
  final String role;
  final String content;
  final DateTime createdAt;

  Message({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };
}