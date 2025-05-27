import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:proyecto_final/core/constants/appwrite_constants.dart';
import 'package:proyecto_final/model/notification_model.dart';

class NotificationRepository {
  final Databases _databases;

  NotificationRepository(this._databases);

  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String message,
    String? relatedListingId,
    String? relatedBuyerId,
    String? relatedBuyerName,
  }) async {
    try {
      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollectionId,
        documentId: ID.unique(),
        data: {
          'recipientId': recipientId,
          'type': type,
          'message': message,
          if (relatedListingId != null) 'relatedListingId': relatedListingId,
          if (relatedBuyerId != null) 'relatedBuyerId': relatedBuyerId,
          if (relatedBuyerName != null) 'relatedBuyerName': relatedBuyerName,
          'isRead': false, 
        },
      );
      print("[NotificationRepository] Notificación creada para $recipientId: $message");
    } catch (e) {
      print("[NotificationRepository] Error creando notificación: $e");
      rethrow;
    }
  }

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollectionId,
        queries: [
          Query.equal('recipientId', userId),
          Query.orderDesc('\$createdAt'), 
        ],
      );
      return response.documents
          .map((doc) => NotificationModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      print("[NotificationRepository] Error obteniendo notificaciones: $e");
      rethrow;
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollectionId,
        documentId: notificationId,
        data: {'isRead': true},
      );
      print("[NotificationRepository] Notificación $notificationId marcada como leída.");
    } catch (e) {
      print("[NotificationRepository] Error marcando notificación como leída: $e");
      rethrow;
    }
  }
  
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollectionId,
        documentId: notificationId,
      );
      print("[NotificationRepository] Notificación $notificationId eliminada.");
    } catch (e) {
      print("[NotificationRepository] Error eliminando notificación: $e");
      rethrow;
    }
  }
}