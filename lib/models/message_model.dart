class MessageSender {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  const MessageSender({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) => MessageSender(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageSender sender;
  final String content;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool isMe;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.sender,
    required this.content,
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
    required this.isMe,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json,
      {required String currentUserId}) {
    final senderId = json['senderId'] as String;
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: senderId,
      sender: MessageSender.fromJson(json['sender'] as Map<String, dynamic>),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      isMe: senderId == currentUserId,
    );
  }
}
