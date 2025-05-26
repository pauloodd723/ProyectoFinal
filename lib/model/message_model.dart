// lib/model/message_model.dart

class MessageModel {
  final String id; // $id del documento de mensaje en Appwrite
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp; // Usaremos $createdAt de Appwrite, parseado a DateTime
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
      timestamp: DateTime.parse(json['\$createdAt'] as String), // Parsear $createdAt
      isRead: json['isRead'] as bool? ?? false, // Default a false si es null
    );
  }

  Map<String, dynamic> toJson() {
    // Usado para crear un mensaje
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      // timestamp ($createdAt) es manejado por Appwrite
      // isRead se puede establecer al crear o actualizar después
      if (isRead != null) 'isRead': isRead,
    };
  }
}
