import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/data/repositories/auth_repository.dart';
import 'package:proyecto_final/controllers/chat_controller.dart';
import 'package:proyecto_final/model/chat_model.dart';
import 'package:proyecto_final/presentation/pages/chat_message_page.dart'; 

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find();
    final AuthController authController = Get.find();
    final String currentUserId = authController.currentUserId ?? '';
    final DateFormat timeFormatter = DateFormat('hh:mm a', 'es_CO');
    final DateFormat dateFormatter = DateFormat('dd/MM/yy', 'es_CO');

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
              indent: 70, 
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
            itemBuilder: (context, index) {
              final ChatModel chat = chatController.chatList[index];
              
              String otherParticipantName = 'Desconocido';
              String? otherParticipantPhotoId; 
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
                otherParticipantName = "Chat guardado"; 
              }


              String lastMessageTimeDisplay = '';
              if (chat.lastMessageTimestamp != null) {
                final now = DateTime.now();
                final lastMsgDate = chat.lastMessageTimestamp!.toLocal();
                if (now.year == lastMsgDate.year &&
                    now.month == lastMsgDate.month &&
                    now.day == lastMsgDate.day) {
                  lastMessageTimeDisplay = timeFormatter.format(lastMsgDate);
                } else {
                  lastMessageTimeDisplay = dateFormatter.format(lastMsgDate); 
                }
              }
              
              String displayPhotoUrl = "https://placehold.co/100x100/7F00FF/FFFFFF?text=${otherParticipantName.isNotEmpty ? otherParticipantName[0].toUpperCase() : '?'}";
              if (otherParticipantPhotoId != null && otherParticipantPhotoId.isNotEmpty) {
                   final AuthRepository authRepo = Get.find(); 
                   displayPhotoUrl = authRepo.getProfilePictureUrl(otherParticipantPhotoId);
              }


              return ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  backgroundImage: NetworkImage(displayPhotoUrl), 
                  onBackgroundImageError: (_, __) {
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
                  String otherParticipantActualId = '';
                   if (otherParticipantIndex != -1 && chat.participants.length > otherParticipantIndex) {
                        otherParticipantActualId = chat.participants[otherParticipantIndex];
                   }

                  if (chat.id.isNotEmpty && otherParticipantActualId.isNotEmpty) {
                    Get.to(() => ChatMessagePage(
                          chatId: chat.id,
                          otherUserId: otherParticipantActualId, 
                          otherUserName: otherParticipantName,
                          otherUserPhotoUrl: displayPhotoUrl, 
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