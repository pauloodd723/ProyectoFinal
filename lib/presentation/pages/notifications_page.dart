// lib/presentation/pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import 'package:proyecto_final/controllers/notification_controller.dart';
import 'package:proyecto_final/model/notification_model.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController controller = Get.find();

    // Formateador de fecha y hora
    final DateFormat dateTimeFormatter = DateFormat('dd/MM/yy, hh:mm a', 'es_CO');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          Obx(() => controller.notifications.any((n) => !n.isRead)
            ? IconButton(
                icon: const Icon(Icons.mark_chat_read_outlined),
                tooltip: 'Marcar todas como leídas (Próximamente)', // Funcionalidad futura
                onPressed: () {
                  // TODO: Implementar "Marcar todas como leídas"
                  Get.snackbar('Próximamente', 'Función para marcar todas como leídas no implementada.');
                },
              )
            : const SizedBox.shrink()
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${controller.error.value}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => controller.fetchNotifications(),
                    child: const Text('Reintentar'),
                  )
                ],
              ),
            )
          );
        }
        if (controller.notifications.isEmpty) {
          return Center(
            child: Text(
              'No tienes notificaciones nuevas.',
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
                    backgroundColor: isRead
                        ? Theme.of(context).colorScheme.surfaceVariant
                        : Theme.of(context).colorScheme.primary,
                    child: Icon(
                      notification.type == 'sale_made'
                          ? Icons.attach_money_rounded
                          : Icons.notifications_active_rounded,
                      color: isRead
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  title: Text(
                    notification.message,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
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
                    // Aquí podrías navegar a una vista relacionada si es aplicable
                    // ej: Get.to(() => ListingDetailPage(listingId: notification.relatedListingId));
                    print("Notificación '${notification.id}' pulsada.");
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