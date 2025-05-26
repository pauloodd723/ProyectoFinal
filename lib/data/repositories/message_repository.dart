// lib/data/repositories/message_repository.dart
import 'package:appwrite/appwrite.dart'; // Para Realtime, Databases, ID, Query
import 'package:appwrite/models.dart';  // Para RealtimeMessage y otros modelos de Appwrite
import 'package:proyecto_final/core/constants/appwrite_constants.dart';
import 'package:proyecto_final/model/message_model.dart';
import 'package:collection/collection.dart'; // Para firstWhereOrNull

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
    // --- INICIO DE SECCIÓN DE DIAGNÓSTICO PARA sendMessage ---
    print("[MessageRepository DIAGNÓSTICO v3] Intentando enviar mensaje.");
    print("[MessageRepository DIAGNÓSTICO v3] ChatID: $chatId, SenderID: $senderId, ReceiverID: $receiverId, Text: $text");
    try {
      final document = await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.messagesCollectionId, // ASEGÚRATE QUE ESTE ID ES CORRECTO
        documentId: ID.unique(),
        data: { // Solo los datos absolutamente necesarios para tu colección 'messages'
          'chatId': chatId,
          'senderId': senderId,
          'receiverId': receiverId,
          'text': text,
          'isRead': false, // Asegurarse que 'isRead' esté definido en tu colección messages
        },
        // NO ESPECIFICAMOS EL PARÁMETRO 'permissions' AQUÍ PARA LA PRUEBA
        // Appwrite usará los permisos por defecto (el creador usualmente obtiene CRUD).
      );
      print("[MessageRepository DIAGNÓSTICO v3] Mensaje enviado con ID: ${document.$id}. Data: ${document.data}");
      
      // MessageModel.fromJson espera que 'document.data' ya contenga $id y $createdAt
      // Lo cual es el caso para la respuesta de createDocument.
      return MessageModel.fromJson(document.data);
    } catch (e) {
      print("[MessageRepository DIAGNÓSTICO v3] Error enviando mensaje: $e");
      if (e is AppwriteException) {
        print("[MessageRepository DIAGNÓSTICO v3] AppwriteException: ${e.message} (Code: ${e.code}, Type: ${e.type})");
      }
      rethrow;
    }
    // --- FIN DE SECCIÓN DE DIAGNÓSTICO ---
  }

  Future<List<MessageModel>> getMessagesForChat(String chatId, {String? cursorId, int limit = 25}) async {
    try {
      print("[MessageRepository] Obteniendo mensajes para el chat $chatId, cursor: $cursorId");
      List<String> queries = [
        Query.equal('chatId', chatId),
        Query.orderDesc('\$createdAt'), // Usar $createdAt para ordenar
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

  Stream<RealtimeMessage> subscribeToNewMessages(String chatId) { // Tipo RealtimeMessage directo
    final String documentChannel = 'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.messagesCollectionId}.documents';
    
    disposeMessagesSubscription(); 

    print("[MessageRepository] Suscribiéndose al canal: $documentChannel para eventos de creación.");
    _messagesSubscription = _realtime.subscribe([documentChannel]);
    
    return _messagesSubscription!.stream.where((response) { // response es RealtimeMessage
      // Acceso a events y payload (son no nulos en la definición de RealtimeMessage del SDK)
      final List<String> events = response.events;
      final Map<String, dynamic> payload = response.payload;

      // Usar firstWhereOrNull de package:collection
      final creationEvent = events.firstWhereOrNull((event) => event.contains('documents.*.create'));
      
      if (creationEvent != null) {
        // El payload debería ser el documento creado
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
        // Este updateDocument fallará si el currentUserId (que es el receiverId)
        // no tiene permiso de UPDATE sobre el documento del mensaje.
        // En sendMessage, añadimos Permission.update(Role.user(receiverId))
        // así que esto debería funcionar para mensajes NUEVOS.
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
      // No relanzar para no interrumpir la experiencia del usuario si esto falla.
    }
  }
}