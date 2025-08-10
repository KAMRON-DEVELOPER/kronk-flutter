class ChatMessageModel {
  final String? id;
  final DateTime createdAt;
  final String chatId;
  final String senderId;
  final String message;
  final bool isRead;

  ChatMessageModel({this.id, required this.createdAt, required this.chatId, required this.senderId, required this.message, this.isRead = false});

  ChatMessageModel copyWith(String? id, DateTime? createdAt, String? chatId, String? senderId, String? message, bool? isRead) {
    return ChatMessageModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch((json['created_at'] as int) * 1000),
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
    );
  }
}
