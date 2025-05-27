import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/controllers/chat_controller.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/data/repositories/user_repository.dart';
import 'package:proyecto_final/model/message_model.dart';
import 'package:proyecto_final/model/user_model.dart';
import 'package:proyecto_final/presentation/pages/midpoint_map_page.dart';

class ChatMessagePage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final String? listingId; 

  const ChatMessagePage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    this.listingId,
  });

  @override
  State<ChatMessagePage> createState() => _ChatMessagePageState();
}

class _ChatMessagePageState extends State<ChatMessagePage> {
  final ChatController _chatController = Get.find();
  final AuthController _authController = Get.find();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final TextEditingController _messageInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    print(
        "[ChatMessagePage] initState for chat ID: ${widget.chatId} with ${widget.otherUserName} (ID: ${widget.otherUserId})");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String currentUserId = _authController.currentUserId ?? '';
      if (currentUserId.isEmpty) {
        if (mounted) {
          Get.snackbar("Error", "No se pudo identificar al usuario actual.");
          Get.back();
        }
        return;
      }
      
      if (_chatController.currentChat.value?.id != widget.chatId) {
        _chatController
            .openOrCreateChat(
          otherUserId: widget.otherUserId,
          listingId: widget.listingId,
        )
            .then((chatModel) {
          if (chatModel != null && chatModel.id == widget.chatId) {
            _scrollToBottom(animated: false);
          } else if (chatModel == null) {
            if (mounted) {
              Get.snackbar("Error", "No se pudo cargar la conversación.");
            }
          }
        });
      } else {
        _chatController.loadMessagesForCurrentChat();
        _chatController.markMessagesAsRead(widget.chatId, currentUserId);
        _scrollToBottom(animated: false);
      }

      _chatController.messages.listen((_) {
        _scrollToBottom();
        if (_chatController.messages.isNotEmpty) {
          final lastMessage = _chatController.messages.last;
          if (lastMessage.receiverId == currentUserId &&
              !(lastMessage.isRead ?? false)) {
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
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageInputController.text.trim();
    if (text.isNotEmpty) {
      _chatController.sendMessage(text);
      _messageInputController.clear();
    }
  }

  void _scrollToBottom({bool animated = true, int delayMs = 100}) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted &&
          _scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: animated ? 300 : 1),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleShowMidpoint() async {
    final UserModel? currentUser = _authController.localUser.value;
    UserModel? otherUserFromRepo;

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      otherUserFromRepo = await _userRepository.getUserById(widget.otherUserId);
    } catch (e) {
      print("[ChatMessagePage] Error obteniendo perfil de ${widget.otherUserId} para punto medio: $e");
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error de Datos", "No se pudo obtener la información del otro usuario.", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (Get.isDialogOpen ?? false) Get.back();

    if (currentUser == null) {
      Get.snackbar("Error de Datos", "No se pudo obtener tu información de usuario.", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (otherUserFromRepo == null) {
      Get.snackbar("Error de Datos", "No se pudo obtener la información del otro usuario.", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (currentUser.latitude == null || currentUser.longitude == null) {
      Get.snackbar(
          "Tu Ubicación No Configurada",
          "Tu ubicación predeterminada no tiene coordenadas. Por favor, edítala en tu perfil (guarda la dirección de nuevo para intentar la geocodificación).",
          duration: const Duration(seconds: 6),
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (otherUserFromRepo.latitude == null || otherUserFromRepo.longitude == null) {
      Get.snackbar(
          "Ubicación del Otro Usuario No Configurada",
          "${otherUserFromRepo.username} no ha configurado coordenadas para su ubicación.",
          duration: const Duration(seconds: 6),
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final double currentLat = currentUser.latitude!;
    final double currentLon = currentUser.longitude!;
    final String currentUserName = currentUser.username;

    final double otherLat = otherUserFromRepo.latitude!;
    final double otherLon = otherUserFromRepo.longitude!;
    final String otherUserName = otherUserFromRepo.username;

    double midLatitude = (currentLat + otherLat) / 2;
    double midLongitude = (currentLon + otherLon) / 2;

    print(
        "Calculando punto medio: UserA ($currentUserName - $currentLat, $currentLon), UserB ($otherUserName - $otherLat, $otherLon), Midpoint ($midLatitude, $midLongitude)");

    Get.to(() => MidpointMapPage(
          userALatitude: currentLat,
          userALongitude: currentLon,
          userAName: "Tú ($currentUserName)",
          userBLatitude: otherLat,
          userBLongitude: otherLon,
          userBName: otherUserName, 
          midpointLatitude: midLatitude,
          midpointLongitude: midLongitude,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _authController.currentUserId ?? '';

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 30,
        titleSpacing: 0,
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
              child: (widget.otherUserPhotoUrl == null ||
                      widget.otherUserPhotoUrl!.isEmpty ||
                      widget.otherUserPhotoUrl!.contains("placehold.co"))
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : "?",
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: "Mostrar punto de encuentro medio",
            onPressed: _handleShowMidpoint,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingMessages.value &&
                  _chatController.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_chatController.messagesError.value.isNotEmpty &&
                  _chatController.messages.isEmpty) {
                return Center(
                    child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      "Error al cargar mensajes: ${_chatController.messagesError.value}",
                      textAlign: TextAlign.center),
                ));
              }
              if (_chatController.messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                        "Envía un mensaje para comenzar la conversación con ${widget.otherUserName}.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600])),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10.0),
                itemCount: _chatController.messages.length,
                itemBuilder: (context, index) {
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

  Widget _buildMessageBubble(
      BuildContext context, MessageModel message, bool isMe) {
    final DateFormat timeFormatter = DateFormat('hh:mm a', 'es_CO');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
            decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18.0),
                  topRight: const Radius.circular(18.0),
                  bottomLeft: isMe
                      ? const Radius.circular(18.0)
                      : const Radius.circular(4.0),
                  bottomRight: isMe
                      ? const Radius.circular(4.0)
                      : const Radius.circular(18.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ]),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: isMe
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5.0),
                Text(
                  timeFormatter.format(message.timestamp.toLocal()),
                  style: TextStyle(
                    fontSize: 10.0,
                    color: (isMe
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant)
                        .withOpacity(0.7),
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageInputController,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: true,
                enableSuggestions: true,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surface
                      .withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
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
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5)),
                  )
                : IconButton(
                    icon: Icon(Icons.send_rounded,
                        color: Theme.of(context).colorScheme.primary, size: 28),
                    onPressed: _sendMessage,
                    tooltip: 'Enviar mensaje',
                  )),
          ],
        ),
      ),
    );
  }
}