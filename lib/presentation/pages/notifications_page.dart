import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/controllers/notification_controller.dart';
import 'package:proyecto_final/model/notification_model.dart';
import 'package:proyecto_final/presentation/pages/seller_profile_page.dart'; 
import 'package:proyecto_final/controllers/auth_controller.dart'; 

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController controller = Get.find();
    final AuthController authController = Get.find();
    final DateFormat dateTimeFormatter = DateFormat('dd/MM/yy, hh:mm a', 'es_CO');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          // ... (tu manejo de error existente)
          return Center(child: Text('Error: ${controller.error.value}'));
        }
        if (controller.notifications.isEmpty) {
          return Center(
            child: Text(
              'No tienes notificaciones.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchNotifications(),
          child: ListView.builder(
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final NotificationModel notification = controller.notifications[index];
              final bool isRead = notification.isRead;

              IconData notificationIconData = Icons.notifications_active_rounded;
              Color iconColor = isRead
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onPrimary;
              Color avatarBgColor = isRead
                  ? Theme.of(context).colorScheme.surfaceVariant
                  : Theme.of(context).colorScheme.primary;

              if (notification.type == 'sale_made') {
                notificationIconData = Icons.monetization_on_outlined;
              } else if (notification.type == 'purchase_confirmation') {
                notificationIconData = Icons.shopping_bag_outlined;
              } else if (notification.type == 'new_message') {
                notificationIconData = Icons.message_outlined;
              }

              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  controller.deleteNotification(notification.id);
                },
                background: Container(
                  color: Theme.of(context).colorScheme.errorContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.delete_sweep_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: avatarBgColor,
                    child: Icon(notificationIconData, color: iconColor),
                  ),
                  title: Text(
                    notification.message,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    dateTimeFormatter.format(notification.createdAt.toLocal()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: isRead
                      ? null
                      : Icon(Icons.circle, color: Theme.of(context).colorScheme.secondary, size: 10),
                  onTap: () {
                    if (!isRead) {
                      controller.markAsRead(notification.id);
                    }

                    if ((notification.type == 'sale_made' || notification.type == 'purchase_confirmation') &&
                        notification.relatedBuyerId != null && notification.relatedBuyerId!.isNotEmpty &&
                        notification.relatedBuyerName != null && notification.relatedBuyerName!.isNotEmpty) {
   
                      if (!authController.isUserLoggedIn) {
                        Get.snackbar("Acción Requerida", "Debes iniciar sesión para ver perfiles.");
                        return;
                      }
                      
                      Get.to(() => SellerProfilePage(
                            sellerId: notification.relatedBuyerId!,
                            sellerName: notification.relatedBuyerName!, 
                          ));
                    } else if (notification.type == 'new_message') {
                      print("Notificación de nuevo mensaje pulsada. ID relacionado: ${notification.relatedBuyerId}");
                    } else {
                      print("Notificación '${notification.id}' de tipo '${notification.type}' pulsada. No hay acción de navegación definida.");
                    }
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }
}