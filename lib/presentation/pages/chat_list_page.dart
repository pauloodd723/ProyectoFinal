// lib/presentation/pages/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/data/repositories/auth_repository.dart';
import 'package:proyecto_final/controllers/chat_controller.dart';
import 'package:proyecto_final/model/chat_model.dart';
// Importaremos ChatMessagePage cuando la creemos
import 'package:proyecto_final/presentation/pages/chat_message_page.dart'; 

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find();
    final AuthController authController = Get.find();
    final String currentUserId = authController.currentUserId ?? '';

    // Formateador de fecha para el último mensaje
    final DateFormat timeFormatter = DateFormat('hh:mm a', 'es_CO');
    final DateFormat dateFormatter = DateFormat('dd/MM/yy', 'es_CO');

    // Llama a loadUserChats si no se ha hecho o para refrescar.
    // chatController.loadUserChats(); // Opcional, onInit del controller ya lo hace.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Mensajes'),
      ),
      body: Obx(() {
        if (chatController.isLoadingChatList.value && chatController.chatList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (chatController.chatListError.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${chatController.chatListError.value}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => chatController.loadUserChats(),
                    child: const Text('Reintentar'),
                  )
                ],
              ),
            ),
          );
        }
        if (chatController.chatList.isEmpty) {
          return Center(
            child: Text(
              'No tienes conversaciones activas.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => chatController.loadUserChats(),
          child: ListView.separated(
            itemCount: chatController.chatList.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 70, // Para alinear con el texto después del avatar
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
            itemBuilder: (context, index) {
              final ChatModel chat = chatController.chatList[index];
              
              // Determinar quién es el otro participante
              String otherParticipantName = 'Desconocido';
              String? otherParticipantPhotoId; // Podría ser null
              int otherParticipantIndex = -1;

              if (chat.participants.length == 2 && chat.participantNames != null && chat.participantNames!.length == 2) {
                if (chat.participants[0] == currentUserId) {
                  otherParticipantIndex = 1;
                } else if (chat.participants[1] == currentUserId) {
                  otherParticipantIndex = 0;
                }
                
                if (otherParticipantIndex != -1) {
                  otherParticipantName = chat.participantNames![otherParticipantIndex];
                  if (chat.participantPhotoIds != null && chat.participantPhotoIds!.length == 2) {
                    otherParticipantPhotoId = chat.participantPhotoIds![otherParticipantIndex];
                  }
                }
              } else if (chat.participants.length == 1 && chat.participants[0] == currentUserId) {
                // Chat consigo mismo o chat grupal donde solo queda 1 (manejar según tu lógica)
                otherParticipantName = "Chat guardado"; // O algo similar
              }


              String lastMessageTimeDisplay = '';
              if (chat.lastMessageTimestamp != null) {
                final now = DateTime.now();
                final lastMsgDate = chat.lastMessageTimestamp!.toLocal();
                if (now.year == lastMsgDate.year &&
                    now.month == lastMsgDate.month &&
                    now.day == lastMsgDate.day) {
                  lastMessageTimeDisplay = timeFormatter.format(lastMsgDate); // Solo hora si es hoy
                } else {
                  lastMessageTimeDisplay = dateFormatter.format(lastMsgDate); // Fecha si es otro día
                }
              }
              
              String displayPhotoUrl = "https://placehold.co/100x100/7F00FF/FFFFFF?text=${otherParticipantName.isNotEmpty ? otherParticipantName[0].toUpperCase() : '?'}";
              if (otherParticipantPhotoId != null && otherParticipantPhotoId.isNotEmpty) {
                   // Usar AuthRepository para construir la URL de la imagen de perfil
                   // Esto asume que AuthRepository tiene un método para obtener la URL de CUALQUIER fileId
                   // o que la lógica para construir URLs está centralizada.
                   // Por ahora, usamos el método del AuthController que es para el usuario actual.
                   // Necesitaríamos un método más genérico o que el ChatModel ya tenga la URL.
                   // Simplificación: usar el método del AuthController si el ID es del AuthController.
                   // Para esta lista, es mejor que ChatModel ya tenga la URL o usar un placeholder.
                   // La lógica de foto en ChatRepository.getOrCreateChat ya guarda el photoId.
                   // Aquí podemos usar AuthRepository para construir la URL si tenemos el ID.
                   final AuthRepository authRepo = Get.find(); // No ideal aquí, mejor pasar la URL o que el modelo la tenga
                   displayPhotoUrl = authRepo.getProfilePictureUrl(otherParticipantPhotoId);
              }


              return ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  backgroundImage: NetworkImage(displayPhotoUrl), // Usar placeholder si es null o vacío
                  onBackgroundImageError: (_, __) {
                    // No hacer nada para que el child (letra) se muestre
                  },
                  child: (otherParticipantPhotoId == null || otherParticipantPhotoId.isEmpty || displayPhotoUrl.contains("placehold.co"))
                    ? Text(
                        otherParticipantName.isNotEmpty ? otherParticipantName[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      )
                    : null,
                ),
                title: Text(
                  otherParticipantName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  chat.lastMessage ?? 'No hay mensajes todavía.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8)),
                ),
                trailing: Text(
                  lastMessageTimeDisplay,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  // Navegar a la pantalla de mensajes para este chat
                  // Pasamos el ChatModel completo o al menos el chatId,
                  // el nombre y la foto del otro participante para el AppBar de ChatMessagePage.
                  String otherParticipantActualId = '';
                   if (otherParticipantIndex != -1 && chat.participants.length > otherParticipantIndex) {
                        otherParticipantActualId = chat.participants[otherParticipantIndex];
                   }

                  if (chat.id.isNotEmpty && otherParticipantActualId.isNotEmpty) {
                    Get.to(() => ChatMessagePage(
                          chatId: chat.id,
                          otherUserId: otherParticipantActualId, // El ID real del otro usuario
                          otherUserName: otherParticipantName,
                          otherUserPhotoUrl: displayPhotoUrl, // O el ID para construirla de nuevo
                        ));
                  } else {
                    Get.snackbar("Error", "No se pudo abrir el chat. Falta información.");
                  }
                },
              );
            },
          ),
        );
      }),
    );
  }
}