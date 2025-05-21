// lib/controllers/notification_controller.dart
import 'package:get/get.dart';
import 'package:proyecto_final/data/repositories/notification_repository.dart';
import 'package:proyecto_final/model/notification_model.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:appwrite/models.dart' as appwrite_models;

class NotificationController extends GetxController {
  final NotificationRepository _repository;
  final AuthController _authController = Get.find<AuthController>();

  NotificationController(this._repository);

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxInt unreadCount = 0.obs;


  @override
  void onInit() {
    super.onInit();
    // Escuchar cambios en el estado de autenticación para cargar/limpiar notificaciones
    ever(_authController.appwriteUser, (appwrite_models.User? user) {
      if (user != null) {
        fetchNotifications();
      } else {
        notifications.clear();
        unreadCount.value = 0;
      }
    });
    // Carga inicial si el usuario ya está logueado
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
      // Actualizar localmente o re-fetch
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !notifications[index].isRead) { // Solo actualiza si realmente cambió
        // Crear un nuevo objeto para asegurar reactividad si los objetos son complejos
        // o simplemente actualizar el estado y contar de nuevo
        // Para este caso, como NotificationModel es simple, podemos intentar una actualización directa
        // pero re-fetching es más seguro para la reactividad completa si hay dudas.
        // notifications[index] = notifications[index].copyWith(isRead: true); // Si tuvieras copyWith
        await fetchNotifications(); // La forma más simple de asegurar consistencia y reactividad
      }
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

  // Método para ser llamado desde PurchasePage
  Future<void> sendSaleNotification({
    required String sellerId,
    required String buyerId,
    required String buyerName,
    required String listingId,
    required String listingTitle,
  }) async {
    try {
      String message = "$buyerName ha comprado tu juego: '$listingTitle'.";
      await _repository.createNotification(
        recipientId: sellerId,
        type: "sale_made",
        message: message,
        relatedListingId: listingId,
        relatedBuyerId: buyerId,
        relatedBuyerName: buyerName,
      );
      print("[NotificationController] Notificación de venta enviada al vendedor $sellerId.");
    } catch (e) {
      print("[NotificationController] Error enviando notificación de venta: $e");
      // Podrías mostrar un error no crítico al comprador si falla el envío de la notificación.
    }
  }
}