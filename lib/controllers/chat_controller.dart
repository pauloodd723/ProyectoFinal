import 'dart:async';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart'; 
import 'package:appwrite/models.dart' as appwrite_models; 
import 'package:proyecto_final/data/repositories/chat_repository.dart';
import 'package:proyecto_final/data/repositories/message_repository.dart';
import 'package:proyecto_final/model/chat_model.dart';
import 'package:proyecto_final/model/message_model.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:collection/collection.dart';
import 'package:proyecto_final/controllers/notification_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/model/game_listing_model.dart';


class ChatController extends GetxController {
  final ChatRepository _chatRepository;
  final MessageRepository _messageRepository;
  late final AuthController _authController;
  late final NotificationController _notificationController;
  late final GameListingController _gameListingController;

  ChatController(this._chatRepository, this._messageRepository);

  final RxList<ChatModel> chatList = <ChatModel>[].obs;
  final RxBool isLoadingChatList = false.obs;
  final RxString chatListError = ''.obs;

  final Rx<ChatModel?> currentChat = Rx<ChatModel?>(null);
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoadingMessages = false.obs;
  final RxString messagesError = ''.obs;
  final RxBool isSendingMessage = false.obs;

  StreamSubscription<RealtimeMessage>? _messageStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    _authController = Get.find<AuthController>();
    _notificationController = Get.find<NotificationController>();
    _gameListingController = Get.find<GameListingController>();
    ever(_authController.appwriteUser, (appwrite_models.User? user) {
      _handleUserChangeForChats(user);
    });

    if (_authController.isUserLoggedIn) {
      loadUserChats();
    }
  }

  void _handleUserChangeForChats(appwrite_models.User? user) {
    if (user != null) {
      loadUserChats();
    } else {
      chatList.clear();
      clearCurrentChatAndSubscription();
    }
  }

  @override
  void onClose() {
    clearCurrentChatAndSubscription();
    super.onClose();
  }

  void clearCurrentChatAndSubscription() {
    _messageStreamSubscription?.cancel();
    _messageStreamSubscription = null;
    _messageRepository.disposeMessagesSubscription();
    currentChat.value = null;
    messages.clear();
    messagesError.value = '';
    print("[ChatController] Chat actual y suscripción limpiados.");
  }

  Future<void> loadUserChats() async {
    if (!_authController.isUserLoggedIn || _authController.currentUserId == null) {
      chatList.clear(); return;
    }
    isLoadingChatList.value = true;
    chatListError.value = '';
    try {
      final chats = await _chatRepository.getUserChats(_authController.currentUserId!);
      chatList.assignAll(chats);
      print("[ChatController] ${chats.length} chats cargados para el usuario.");
    } catch (e) {
      print("[ChatController] Error cargando lista de chats: $e");
      chatListError.value = "No se pudieron cargar tus conversaciones.";
    } finally {
      isLoadingChatList.value = false;
    }
  }

  Future<ChatModel?> openOrCreateChat({ required String otherUserId, String? listingId }) async {
    if (!_authController.isUserLoggedIn || _authController.currentUserId == null) {
      Get.snackbar("Error de Autenticación", "Debes iniciar sesión para chatear.");
      return null;
    }
    final String currentUserId = _authController.currentUserId!;
    
    clearCurrentChatAndSubscription(); 
    
    isLoadingMessages.value = true; 
    messagesError.value = '';
    currentChat.value = null; 

    print("[ChatController] Intentando abrir/crear chat con $otherUserId (listing: $listingId)");
    try {
      final chat = await _chatRepository.getOrCreateChat(
        currentUserId: currentUserId, otherUserId: otherUserId, listingId: listingId,
      );
      
      if (chat != null) {
        currentChat.value = chat; 
        print("[ChatController] Chat actual ESTABLECIDO a ID: ${currentChat.value!.id}, Participantes: ${currentChat.value!.participants}");
        await loadMessagesForCurrentChat(); 
        subscribeToMessages(chat.id);       
        await markMessagesAsRead(chat.id, currentUserId); 
        isLoadingMessages.value = false; 
        return chat;
      } else {
        messagesError.value = "No se pudo iniciar o encontrar el chat.";
        print("[ChatController] Falló getOrCreateChat en ChatRepository (devolvió null).");
        isLoadingMessages.value = false;
        return null;
      }
    } catch (e) {
      print("[ChatController] EXCEPCIÓN abriendo o creando chat: $e");
      messagesError.value = "Error crítico al iniciar el chat.";
      currentChat.value = null; 
      isLoadingMessages.value = false;
      return null;
    }
  }
  
  Future<void> loadMessagesForCurrentChat({String? cursorId}) async {
    if (currentChat.value == null) {
      print("[ChatController] No hay chat actual (currentChat.value es null) para cargar mensajes.");
      messages.clear();
      isLoadingMessages.value = false; 
      return;
    }
    if (cursorId == null) { 
        messages.clear();
        isLoadingMessages.value = true;
    }
    messagesError.value = '';
    try {
      print("[ChatController] Cargando mensajes para el chat: ${currentChat.value!.id}");
      final fetchedMessages = await _messageRepository.getMessagesForChat(
        currentChat.value!.id, cursorId: cursorId,
      );
      if (cursorId == null) {
        messages.assignAll(fetchedMessages.reversed.toList());
      } else {
        messages.insertAll(0, fetchedMessages.reversed.toList());
      }
      print("[ChatController] ${fetchedMessages.length} mensajes cargados. Total ahora: ${messages.length}");
    } catch (e) {
      print("[ChatController] Error cargando mensajes: $e");
      messagesError.value = "No se pudieron cargar los mensajes.";
    } finally {
      if (cursorId == null) isLoadingMessages.value = false;
    }
  }

  void subscribeToMessages(String chatId) {
    print("[ChatController] Intentando suscribirse a mensajes para el chat: $chatId");
    
    _messageStreamSubscription = _messageRepository.subscribeToNewMessages(chatId).listen(
      (RealtimeMessage realtimeMessage) { 
        final List<String> events = realtimeMessage.events;
        final Map<String, dynamic> payload = realtimeMessage.payload;
        print("[ChatController] Mensaje Realtime recibido. Eventos: $events, Payload: $payload");
        try {
          if (payload.isNotEmpty) {
            final newMessage = MessageModel.fromJson(payload);
            if (!messages.any((m) => m.id == newMessage.id)) {
              messages.add(newMessage);
              _updateChatListWithNewMessage(newMessage);
              if (newMessage.receiverId == _authController.currentUserId && 
                  currentChat.value != null &&
                  currentChat.value!.id == chatId &&
                  Get.currentRoute == '/ChatMessagePage') { 
                    markMessagesAsRead(chatId, _authController.currentUserId!);
              }
            }
          }
        } catch (e) {
          print("[ChatController] Error procesando mensaje de Realtime: $e. Payload: $payload");
        }
      },
      onError: (error) {
        print("[ChatController] Error en la suscripción de mensajes Realtime: $error");
        messagesError.value = "Error de conexión en tiempo real.";
      },
      onDone: (){
        print("[ChatController] Suscripción a mensajes Realtime finalizada para el chat $chatId.");
      }
    );
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    if (chatId.isNotEmpty && userId.isNotEmpty && currentChat.value != null && currentChat.value!.id == chatId) {
      print("[ChatController] Marcando chat $chatId como leído para el usuario $userId");
      await _messageRepository.markMessagesAsRead(chatId, userId);
    } else {
      print("[ChatController] No se marcaron mensajes como leídos: chatId ($chatId) no coincide con chat actual (${currentChat.value?.id}) o userId ($userId) vacío.");
    }
  }

  Future<void> sendMessage(String text) async {
    print("[ChatController.sendMessage] Intentando enviar: '$text'");

    if (currentChat.value == null || text.trim().isEmpty || !_authController.isUserLoggedIn || _authController.currentUserId == null) {
      print("[ChatController] CONDICIÓN FALLIDA: No se puede enviar mensaje.");
      if(currentChat.value == null) Get.snackbar("Error", "No hay un chat activo para enviar el mensaje.");
      if(!_authController.isUserLoggedIn) Get.snackbar("Error", "Debes estar logueado para enviar mensajes.");
      return;
    }

    isSendingMessage.value = true;
    final String currentUserId = _authController.currentUserId!;
    final String? senderName = _authController.currentUserName; 
    final String? receiverId = currentChat.value!.participants.firstWhereOrNull((id) => id != currentUserId);

    if (receiverId == null || receiverId.isEmpty) {
      Get.snackbar("Error de Envío", "No se pudo identificar al destinatario del chat.");
      isSendingMessage.value = false;
      return;
    }
     if (senderName == null || senderName.isEmpty) {
      Get.snackbar("Error de Envío", "No se pudo identificar tu nombre de usuario para la notificación.");
      isSendingMessage.value = false;
      return;
    }

    try {
      MessageModel sentMessage = await _messageRepository.sendMessage(
        chatId: currentChat.value!.id,
        senderId: currentUserId,
        receiverId: receiverId,
        text: text.trim(),
      );
      
      await _chatRepository.updateChatOnNewMessage(
          chatId: currentChat.value!.id,
          lastMessage: text.trim(),
      );
      _updateChatListWithNewMessage(sentMessage); 

      String? listingTitleForNotification;
      final String? listingIdForNotification = currentChat.value!.listingId;

      if (listingIdForNotification != null && listingIdForNotification.isNotEmpty) {
        final GameListingModel? listing = _gameListingController.listings.firstWhereOrNull(
          (l) => l.id == listingIdForNotification
        );
        if (listing != null) {
          listingTitleForNotification = listing.title;
        } else {
          print("[ChatController] No se encontró el título del anuncio $listingIdForNotification para la notificación.");
        }
      }

      await _notificationController.sendNewMessageNotification(
        recipientId: receiverId,      
        senderId: currentUserId,      
        senderName: senderName,       
        listingId: listingIdForNotification,
        listingTitle: listingTitleForNotification,
        chatId: currentChat.value!.id,
      );

      print("[ChatController] Mensaje enviado: '${sentMessage.text}' y notificación programada.");
    } catch (e) {
      print("[ChatController] Error enviando mensaje o notificación: $e");
      Get.snackbar("Error", "No se pudo enviar el mensaje.");
    } finally {
      isSendingMessage.value = false;
    }
  }
  
  void _updateChatListWithNewMessage(MessageModel message) {
      final chatIndex = chatList.indexWhere((chat) => chat.id == message.chatId);
    if (chatIndex != -1) {
        final ChatModel oldChat = chatList[chatIndex];
        final updatedChat = oldChat.copyWith( 
            lastMessage: message.text.length > 50 ? '${message.text.substring(0,47)}...' : message.text,
            lastMessageTimestamp: message.timestamp
        );
        chatList[chatIndex] = updatedChat;
        chatList.sort((a, b) {
          final dateA = a.lastMessageTimestamp ?? DateTime(1970);
          final dateB = b.lastMessageTimestamp ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
        print("[ChatController] Lista de chats actualizada para el chat ID: ${message.chatId}");
    } else {
        print("[ChatController] No se encontró el chat ${message.chatId} en chatList para actualizar. Recargando lista de chats.");
        loadUserChats(); 
    }
  }
}