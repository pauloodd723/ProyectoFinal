class NotificationModel {
  final String id; 
  final String recipientId;
  final String type; 
  final String message;
  final String? relatedListingId;
  final String? relatedBuyerId; 
  final String? relatedBuyerName; 
  final bool isRead;
  final DateTime createdAt; 

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.message,
    this.relatedListingId,
    this.relatedBuyerId,
    this.relatedBuyerName,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['\$id'],
      recipientId: json['recipientId'],
      type: json['type'],
      message: json['message'],
      relatedListingId: json['relatedListingId'],
      relatedBuyerId: json['relatedBuyerId'],
      relatedBuyerName: json['relatedBuyerName'],
      isRead: json['isRead'] ?? false,
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'])
          : DateTime.now(), 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipientId': recipientId,
      'type': type,
      'message': message,
      if (relatedListingId != null) 'relatedListingId': relatedListingId,
      if (relatedBuyerId != null) 'relatedBuyerId': relatedBuyerId,
      if (relatedBuyerName != null) 'relatedBuyerName': relatedBuyerName,
      'isRead': isRead,
    };
  }
}