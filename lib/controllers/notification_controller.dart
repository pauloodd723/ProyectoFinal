// lib/controllers/notification_controller.dart
import 'package:get/get.dart';
import 'package:proyecto_final/data/repositories/notification_repository.dart';
import 'package:proyecto_final/model/notification_model.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:appwrite/models.dart' as appwrite_auth_models; // Para User de Appwrite Auth
import 'package:proyecto_final/data/repositories/user_repository.dart'; // Para obtener datos del vendedor
import 'package:proyecto_final/model/user_model.dart'; // Para UserModel de tu colección 'users'

class NotificationController extends GetxController {
  final NotificationRepository _repository;
  final AuthController _authController = Get.find<AuthController>();
  final UserRepository _userRepository = Get.find<UserRepository>(); // Inyectar UserRepository

  NotificationController(this._repository);

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_authController.appwriteUser, (appwrite_auth_models.User? user) {
      if (user != null) {
        fetchNotifications();
      } else {
        notifications.clear();
        unreadCount.value = 0;
      }
    });
    if (_authController.isUserLoggedIn) {
      fetchNotifications();
    }
  }

  Future<void> fetchNotifications() async {
    if (_authController.currentUserId == null) {
      notifications.clear();
      unreadCount.value = 0;
      return;
    }
    isLoading.value = true;
    error.value = '';
    try {
      final fetchedNotifications = await _repository.getUserNotifications(_authController.currentUserId!);
      notifications.assignAll(fetchedNotifications);
      _updateUnreadCount();
      print("[NotificationController] Notificaciones cargadas: ${notifications.length}, No leídas: ${unreadCount.value}");
    } catch (e) {
      print("[NotificationController] Error al cargar notificaciones: $e");
      error.value = "No se pudieron cargar las notificaciones.";
      notifications.clear();
      unreadCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }
  
  void _updateUnreadCount() {
      unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markNotificationAsRead(notificationId);
      await fetchNotifications(); 
    } catch (e) {
      print("[NotificationController] Error al marcar como leída: $e");
      Get.snackbar("Error", "No se pudo actualizar la notificación.");
    }
  }
  
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
      notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
      Get.snackbar("Éxito", "Notificación eliminada.");
    } catch (e) {
      print("[NotificationController] Error al eliminar notificación: $e");
      Get.snackbar("Error", "No se pudo eliminar la notificación.");
    }
  }

  // Notificación para el VENDEDOR cuando se realiza una venta
  Future<void> sendSaleNotificationToSeller({
    required String sellerId,    // ID del vendedor
    required String buyerId,     // ID del comprador
    required String buyerName,   // Nombre del comprador
    required String listingId,
    required String listingTitle,
  }) async {
    try {
      String message = "$buyerName ha comprado tu juego: '$listingTitle'. ¡Prepara la entrega!";
      
      await _repository.createNotification(
        recipientId: sellerId, // Notificación para el vendedor
        type: "sale_made",
        message: message,
        relatedListingId: listingId,
        relatedBuyerId: buyerId, 
        relatedBuyerName: buyerName,
      );
      print("[NotificationController] Notificación de venta enviada al vendedor $sellerId.");
    } catch (e) {
      print("[NotificationController] Error enviando notificación de venta al vendedor: $e");
    }
  }

  // Notificación para el COMPRADOR después de una compra
  Future<void> sendPurchaseConfirmationToBuyer({
    required String buyerId,
    required String listingId,
    required String listingTitle,
    required String sellerId, // Para obtener la dirección del vendedor
  }) async {
    try {
      UserModel? sellerProfile = await _userRepository.getUserById(sellerId);
      String sellerAddressInfo = "Contacta al vendedor para coordinar la entrega.";
      if (sellerProfile?.defaultAddress != null && sellerProfile!.defaultAddress!.isNotEmpty) {
        sellerAddressInfo = "Puedes recoger el juego en la ubicación del vendedor: ${sellerProfile.defaultAddress}.";
      } else {
        sellerAddressInfo = "El vendedor no ha especificado una dirección predeterminada. Contacta para coordinar la entrega.";
      }

      String message = "¡Felicidades! Compraste '$listingTitle'. $sellerAddressInfo";
      
      await _repository.createNotification(
        recipientId: buyerId,
        type: "purchase_confirmation",
        message: message,
        relatedListingId: listingId,
        relatedBuyerId: sellerId, // ID del vendedor
        relatedBuyerName: sellerProfile?.username ?? "Vendedor",
      );
       print("[NotificationController] Notificación de confirmación de compra enviada al comprador $buyerId.");
    } catch (e) {
      print("[NotificationController] Error enviando notificación de confirmación de compra al comprador: $e");
    }
  }

  // Notificación para el RECEPTOR de un nuevo mensaje de CHAT
  Future<void> sendNewMessageNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    String? listingId,
    String? listingTitle,
    String? chatId,
  }) async {
    try {
      String notificationMessage;
      if (listingTitle != null && listingTitle.isNotEmpty) {
        notificationMessage = "$senderName te envió un mensaje sobre '$listingTitle'.";
      } else if (listingId != null && listingId.isNotEmpty) {
        notificationMessage = "$senderName te envió un mensaje (Anuncio ID: $listingId).";
      } else {
        notificationMessage = "$senderName te envió un nuevo mensaje.";
      }

      await _repository.createNotification(
        recipientId: recipientId,
        type: "new_message",
        message: notificationMessage,
        relatedListingId: listingId,
        relatedBuyerId: senderId,    // Usamos este campo para el ID del remitente del mensaje
        relatedBuyerName: senderName,// Usamos este campo para el nombre del remitente del mensaje
      );
      print("[NotificationController] Notificación de nuevo mensaje enviada al destinatario $recipientId.");
    } catch (e) {
      print("[NotificationController] Error enviando notificación de nuevo mensaje: $e");
    }
  }
}