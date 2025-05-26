// lib/model/chat_model.dart

class ChatModel {
  final String id; // $id del documento de chat en Appwrite
  final List<String> participants; // IDs de los usuarios en el chat
  final List<String>? participantNames; // Nombres para mostrar en la lista de chats
  final List<String>? participantPhotoIds; // IDs de las fotos de perfil para la lista de chats
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final String? listingId; // ID del anuncio relacionado, si existe
  // Considera añadir Map<String, int> unreadCounts; para contadores por participante

  ChatModel({
    required this.id,
    required this.participants,
    this.participantNames,
    this.participantPhotoIds,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.listingId,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['\$id'] as String,
      participants: List<String>.from(json['participants'] as List<dynamic>? ?? []),
      participantNames: json['participantNames'] != null
          ? List<String>.from(json['participantNames'] as List<dynamic>)
          : null,
      participantPhotoIds: json['participantPhotoIds'] != null
          ? List<String>.from(json['participantPhotoIds'] as List<dynamic>)
          : null,
      lastMessage: json['lastMessage'] as String?,
      lastMessageTimestamp: json['lastMessageTimestamp'] != null
          ? DateTime.tryParse(json['lastMessageTimestamp'] as String)
          : null,
      listingId: json['listingId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    // Usado para crear o actualizar un chat
    return {
      'participants': participants,
      if (participantNames != null) 'participantNames': participantNames,
      if (participantPhotoIds != null) 'participantPhotoIds': participantPhotoIds,
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageTimestamp != null) 'lastMessageTimestamp': lastMessageTimestamp!.toIso8601String(),
      if (listingId != null) 'listingId': listingId,
    };
  }

  // Método copyWith para facilitar actualizaciones inmutables en el ChatController
  ChatModel copyWith({
    String? id,
    List<String>? participants,
    List<String>? participantNames,
    List<String>? participantPhotoIds,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
    String? listingId,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      participantPhotoIds: participantPhotoIds ?? this.participantPhotoIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      listingId: listingId ?? this.listingId,
    );
  }
}
