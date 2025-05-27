class ChatModel {
  final String id; 
  final List<String> participants; 
  final List<String>? participantNames;
  final List<String>? participantPhotoIds; 
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final String? listingId;

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
    return {
      'participants': participants,
      if (participantNames != null) 'participantNames': participantNames,
      if (participantPhotoIds != null) 'participantPhotoIds': participantPhotoIds,
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageTimestamp != null) 'lastMessageTimestamp': lastMessageTimestamp!.toIso8601String(),
      if (listingId != null) 'listingId': listingId,
    };
  }

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
