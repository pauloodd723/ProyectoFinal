import 'package:appwrite/appwrite.dart'; 
import 'package:appwrite/models.dart'; 
import 'package:proyecto_final/core/constants/appwrite_constants.dart';
import 'package:proyecto_final/model/message_model.dart';
import 'package:collection/collection.dart'; 

class MessageRepository {
  final Databases _databases;
  final Realtime _realtime;
  RealtimeSubscription? _messagesSubscription;

  MessageRepository(this._databases, this._realtime);

  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    print("[MessageRepository DIAGNÓSTICO v3] Intentando enviar mensaje.");
    print("[MessageRepository DIAGNÓSTICO v3] ChatID: $chatId, SenderID: $senderId, ReceiverID: $receiverId, Text: $text");
    try {
      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollectionId, 
        documentId: ID.unique(),
        data: { 
          'chatId': chatId,
          'senderId': senderId,
          'receiverId': receiverId,
          'text': text,
          'isRead': false, 
        },
      );
      print("[MessageRepository DIAGNÓSTICO v3] Mensaje enviado con ID: ${document.$id}. Data: ${document.data}");
      
      return MessageModel.fromJson(document.data);
    } catch (e) {
      print("[MessageRepository DIAGNÓSTICO v3] Error enviando mensaje: $e");
      if (e is AppwriteException) {
        print("[MessageRepository DIAGNÓSTICO v3] AppwriteException: ${e.message} (Code: ${e.code}, Type: ${e.type})");
      }
      rethrow;
    }
  }

  Future<List<MessageModel>> getMessagesForChat(String chatId, {String? cursorId, int limit = 25}) async {
    try {
      print("[MessageRepository] Obteniendo mensajes para el chat $chatId, cursor: $cursorId");
      List<String> queries = [
        Query.equal('chatId', chatId),
        Query.orderDesc('\$createdAt'),
        Query.limit(limit),
      ];
      if (cursorId != null) {
        queries.add(Query.cursorAfter(cursorId));
      }

      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollectionId,
        queries: queries,
      );
      print("[MessageRepository] ${response.documents.length} mensajes encontrados para el chat $chatId.");
      return response.documents
          .map((doc) => MessageModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      print("[MessageRepository] Error obteniendo mensajes para el chat $chatId: $e");
      if (e is AppwriteException) {
        print("[MessageRepository] AppwriteException: ${e.message} (Code: ${e.code}, Type: ${e.type})");
      }
      rethrow;
    }
  }

  Stream<RealtimeMessage> subscribeToNewMessages(String chatId) { 
    final String documentChannel = 'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.messagesCollectionId}.documents';
    
    disposeMessagesSubscription(); 

    print("[MessageRepository] Suscribiéndose al canal: $documentChannel para eventos de creación.");
    _messagesSubscription = _realtime.subscribe([documentChannel]);
    
    return _messagesSubscription!.stream.where((response) { 
      final List<String> events = response.events;
      final Map<String, dynamic> payload = response.payload;
      final creationEvent = events.firstWhereOrNull((event) => event.contains('documents.*.create'));
      
      if (creationEvent != null) {
        if (payload.isNotEmpty) { 
          return payload['chatId'] == chatId;
        }
      }
      return false;
    });
  }

  void disposeMessagesSubscription() {
    if (_messagesSubscription != null) {
      print("[MessageRepository] Cerrando suscripción a mensajes Realtime.");
      _messagesSubscription!.close();
      _messagesSubscription = null;
    }
  }

  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    print("[MessageRepository] Intentando marcar mensajes como leídos para chat $chatId y usuario $currentUserId");
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollectionId,
        queries: [
          Query.equal('chatId', chatId),
          Query.equal('receiverId', currentUserId),
          Query.equal('isRead', false),
        ],
      );

      if (response.documents.isEmpty) {
        print("[MessageRepository] No hay mensajes no leídos para marcar para el usuario $currentUserId en el chat $chatId.");
        return;
      }

      print("[MessageRepository] Marcando ${response.documents.length} mensajes como leídos.");
      for (var doc in response.documents) {
        await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.messagesCollectionId,
          documentId: doc.$id,
          data: {'isRead': true},
        );
      }
      print("[MessageRepository] Mensajes marcados como leídos exitosamente.");
    } catch (e) {
      print("[MessageRepository] Error marcando mensajes como leídos: $e");
      if (e is AppwriteException) {
        print("[MessageRepository] AppwriteException: ${e.message} (Code: ${e.code}, Type: ${e.type})");
      }
    }
  }
}