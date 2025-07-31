class ChatMessageModel {
  final String? id;
  final String chatId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  ChatMessageModel({this.id, required this.chatId, required this.senderId, required this.message, required this.createdAt});

  ChatMessageModel copyWith(String? id, String? chatId, String? senderId, String? message, DateTime? createdAt) {
    return ChatMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // "last_message": {
  // "id": "d351ba6e07804dd6825f5bf90b7a856a",
  // "sender_id": "96f90d7fda694128b27d0a0792600eae",
  // "chat_id": "51c3cb5c551148cdaab3023219f56481",
  // "message": "Hi brother.",
  // "created_at": 1753288562
  // }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      message: json['message'],
      createdAt: DateTime.fromMillisecondsSinceEpoch((json['created_at'] as int) * 1000),
    );
  }
}
