// lib/presentation/pages/chat_message_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/controllers/chat_controller.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/model/message_model.dart';

class ChatMessagePage extends StatefulWidget {
  final String chatId; // ID del chat que esta página va a mostrar
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  const ChatMessagePage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
  });

  @override
  State<ChatMessagePage> createState() => _ChatMessagePageState();
}

class _ChatMessagePageState extends State<ChatMessagePage> {
  final ChatController _chatController = Get.find();
  final AuthController _authController = Get.find();
  final TextEditingController _messageInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    print("[ChatMessagePage] initState for chat ID: ${widget.chatId} with ${widget.otherUserName}");

    // Es crucial que el ChatController esté configurado para ESTE chat.
    // La navegación desde ChatListPage ya debería haber llamado a openOrCreateChat.
    // Aquí nos aseguramos de que, si por alguna razón no es el chat actual, se intente configurar.
    // También cargamos mensajes y marcamos como leídos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String currentUserId = _authController.currentUserId ?? '';
      if (currentUserId.isEmpty) {
        print("[ChatMessagePage] Error: currentUserId is empty in initState. Cannot proceed.");
        if (mounted) {
          Get.snackbar("Error", "No se pudo identificar al usuario actual.");
          Get.back(); // Volver si no hay usuario
        }
        return;
      }

      // Si el chat actual en el controlador no es este, intenta abrirlo/establecerlo.
      // Esto también cargará mensajes y suscribirá.
      if (_chatController.currentChat.value?.id != widget.chatId) {
        print("[ChatMessagePage] Chat ID ${widget.chatId} no es el actual en ChatController. Abriendo/Estableciendo contexto...");
        _chatController.openOrCreateChat(
          otherUserId: widget.otherUserId,
          // listingId: Si tienes un listingId asociado a este chat, pásalo aquí.
          // Por ahora, si el chat ya existe por chatId, esta función debería encontrarlo
          // y establecerlo como currentChat, o crear uno nuevo si es necesario.
        ).then((chatModel) {
          if (chatModel != null && chatModel.id == widget.chatId) {
            // markMessagesAsRead ya se llama dentro de openOrCreateChat en el controller
            _scrollToBottom(animated: false);
          } else if (chatModel == null) {
            print("[ChatMessagePage] No se pudo abrir o crear el chat desde initState para ${widget.chatId}.");
            if(mounted) Get.snackbar("Error", "No se pudo cargar la conversación.");
          }
        });
      } else {
        // El chat ya es el activo. Solo asegúrate de que los mensajes estén cargados y marcados como leídos.
        print("[ChatMessagePage] Chat ${widget.chatId} ya es el actual. Cargando mensajes y marcando como leído.");
        _chatController.loadMessagesForCurrentChat(); // Carga si no se han cargado
        _chatController.markMessagesAsRead(widget.chatId, currentUserId); // Usa el método del controller
        _scrollToBottom(animated: false);
      }

      // Escuchar cambios en la lista de mensajes para hacer scroll
      // y para marcar como leídos si llegan nuevos mensajes mientras la pantalla está visible.
      _chatController.messages.listen((_) {
        _scrollToBottom();
        // Si llegan nuevos mensajes y el usuario actual es el receptor, marcarlos como leídos.
        if (_chatController.messages.isNotEmpty) {
          final lastMessage = _chatController.messages.last;
          if (lastMessage.receiverId == currentUserId && !(lastMessage.isRead ?? false)) {
            _chatController.markMessagesAsRead(widget.chatId, currentUserId);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _messageInputController.dispose();
    _scrollController.dispose();
    // Considera si quieres limpiar el currentChat en el ChatController al salir de esta página.
    // Si el usuario puede volver rápidamente a este chat, quizás no quieras limpiarlo.
    // Si cada vez que entra a un chat se llama a openOrCreateChat, entonces está bien.
    // _chatController.clearCurrentChatAndSubscription(); // Descomenta si quieres limpiar al salir.
    print("[ChatMessagePage] dispose para chat ID: ${widget.chatId}");
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageInputController.text.trim();
    if (text.isNotEmpty) {
      _chatController.sendMessage(text);
      _messageInputController.clear();
      // El scroll se manejará por el listener de _chatController.messages
    }
  }

  void _scrollToBottom({bool animated = true, int delayMs = 100}) {
    // Esperar un breve momento para que el ListView se actualice con los nuevos mensajes
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted && _scrollController.hasClients && _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: animated ? 300 : 1),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _authController.currentUserId ?? '';

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 30, // Ajustar para que el título tenga más espacio
        titleSpacing: 0,  // Reducir espaciado del título
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              backgroundImage: (widget.otherUserPhotoUrl != null &&
                      widget.otherUserPhotoUrl!.isNotEmpty &&
                      !widget.otherUserPhotoUrl!.contains("placehold.co"))
                  ? NetworkImage(widget.otherUserPhotoUrl!)
                  : null,
              onBackgroundImageError: (_, __) { /* Silenciar error si la imagen no carga */ },
              child: (widget.otherUserPhotoUrl == null ||
                      widget.otherUserPhotoUrl!.isEmpty ||
                      widget.otherUserPhotoUrl!.contains("placehold.co"))
                  ? Text(widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : "?",
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded( // Para que el nombre no se desborde
              child: Text(
                widget.otherUserName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // Aquí podrías añadir un botón para ver el perfil del otro usuario si lo deseas
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.info_outline),
        //     onPressed: () {
        //       // Navegar a SellerProfilePage(sellerId: widget.otherUserId, sellerName: widget.otherUserName)
        //     },
        //   ),
        // ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              // Verificar si el chat actual en el controlador es el de esta página
              if (_chatController.currentChat.value?.id != widget.chatId && !_chatController.isLoadingMessages.value) {
                // Si no es el chat correcto y no está cargando, podría ser un estado intermedio.
                // Se podría mostrar un loader o un mensaje, o esperar a que initState lo resuelva.
                // Por ahora, si los mensajes están vacíos, se mostrará el estado de carga o "sin mensajes".
                print("[ChatMessagePage] Warning: currentChat.id (${_chatController.currentChat.value?.id}) != widget.chatId (${widget.chatId})");
              }

              if (_chatController.isLoadingMessages.value && _chatController.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_chatController.messagesError.value.isNotEmpty && _chatController.messages.isEmpty) {
                 return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Error al cargar mensajes: ${_chatController.messagesError.value}", textAlign: TextAlign.center),
                    )
                  );
              }
              if (_chatController.messages.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("Envía un mensaje para comenzar la conversación.", textAlign: TextAlign.center),
                  )
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10.0),
                // reverse: true, // Si quieres que los mensajes se muestren de abajo hacia arriba y el input arriba
                itemCount: _chatController.messages.length,
                itemBuilder: (context, index) {
                  // Si reverse es true, accede a los mensajes en orden inverso:
                  // final MessageModel message = _chatController.messages[(_chatController.messages.length - 1) - index];
                  final MessageModel message = _chatController.messages[index];
                  final bool isMe = message.senderId == currentUserId;
                  return _buildMessageBubble(context, message, isMe);
                },
              );
            }),
          ),
          _buildMessageInputField(context),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, MessageModel message, bool isMe) {
    final DateFormat timeFormatter = DateFormat('hh:mm a', 'es_CO');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0), // Espacio entre burbujas
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
            decoration: BoxDecoration(
              color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18.0),
                topRight: const Radius.circular(18.0),
                bottomLeft: isMe ? const Radius.circular(18.0) : const Radius.circular(4.0),
                bottomRight: isMe ? const Radius.circular(4.0) : const Radius.circular(18.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5.0),
                Text(
                  timeFormatter.format(message.timestamp.toLocal()),
                  style: TextStyle(
                    fontSize: 10.0,
                    color: (isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 5,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end, // Alinear items si el TextField crece
          children: [
            // IconButton(icon: Icon(Icons.add_photo_alternate_outlined), onPressed: () { /* Para enviar imágenes */ }),
            Expanded(
              child: TextField(
                controller: _messageInputController,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: true,
                enableSuggestions: true,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1), // Un color de fondo sutil
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Ajustar padding
                ),
                onSubmitted: (text) => _sendMessage(),
                minLines: 1,
                maxLines: 5,
              ),
            ),
            const SizedBox(width: 6),
            Obx(() => _chatController.isSendingMessage.value
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  )
                : IconButton(
                    icon: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                    onPressed: _sendMessage,
                    tooltip: 'Enviar mensaje',
                  )
            ),
          ],
        ),
      ),
    );
  }
}