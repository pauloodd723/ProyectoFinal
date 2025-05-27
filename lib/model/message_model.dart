class MessageModel {
  final String id; 
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp; 
  final bool? isRead;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['\$id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['\$createdAt'] as String), 
      isRead: json['isRead'] as bool? ?? false, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      if (isRead != null) 'isRead': isRead,
    };
  }
}
