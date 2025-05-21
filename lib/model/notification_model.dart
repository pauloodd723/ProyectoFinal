
class NotificationModel {
  final String id; // $id del documento de Appwrite
  final String recipientId;
  final String type; // ej: "sale_made", "new_listing_followed_seller", "coupon_received"
  final String message;
  final String? relatedListingId;
  final String? relatedBuyerId; // Quién realizó la acción que generó la notificación
  final String? relatedBuyerName; // Nombre del que realizó la acción
  final bool isRead;
  final DateTime createdAt; // Se parseará desde Appwrite $createdAt

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
          : DateTime.now(), // Fallback, aunque $createdAt siempre debería existir
    );
  }

  Map<String, dynamic> toJson() {
    // Usado para crear notificaciones
    return {
      'recipientId': recipientId,
      'type': type,
      'message': message,
      if (relatedListingId != null) 'relatedListingId': relatedListingId,
      if (relatedBuyerId != null) 'relatedBuyerId': relatedBuyerId,
      if (relatedBuyerName != null) 'relatedBuyerName': relatedBuyerName,
      'isRead': isRead,
      // '$createdAt' y '$id' son manejados por Appwrite
    };
  }
}