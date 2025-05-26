// lib/data/repositories/chat_repository.dart
import 'package:appwrite/appwrite.dart';
import 'package:proyecto_final/core/constants/appwrite_constants.dart';
import 'package:proyecto_final/model/chat_model.dart';
import 'package:proyecto_final/model/user_model.dart';
import 'package:proyecto_final/data/repositories/user_repository.dart';

class ChatRepository {
  final Databases _databases;
  final UserRepository _userRepository;

  ChatRepository(this._databases, this._userRepository);

  Future<ChatModel?> getOrCreateChat({
    required String currentUserId,
    required String otherUserId,
    String? listingId,
  }) async {
    List<String> participantsArray = [currentUserId, otherUserId]..sort((a, b) => a.compareTo(b));
    print("[ChatRepository] getOrCreateChat para participantes: $participantsArray (listingId: $listingId)");

    try {
      print("[ChatRepository] Buscando chat existente...");
      List<String> queries = [
        Query.equal('participants', participantsArray),
      ];
      
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chatsCollectionId,
        queries: queries,
      );

      if (response.documents.isNotEmpty) {
        print("[ChatRepository] Chat existente encontrado con ID: ${response.documents.first.$id}");
        return ChatModel.fromJson(response.documents.first.data);
      } else {
        print("[ChatRepository] No se encontró chat existente con participants $participantsArray. Creando uno nuevo...");
        UserModel? currentUserProfile = await _userRepository.getUserById(currentUserId);
        UserModel? otherUserProfile = await _userRepository.getUserById(otherUserId);

        if (currentUserProfile == null || otherUserProfile == null) {
          // CORREGIDO AQUÍ: Acceder a .$id en lugar de .id
          print("[ChatRepository] Error: No se pudo obtener el perfil de uno o ambos usuarios. CurrentUser: ${currentUserProfile?.$id}, OtherUser: ${otherUserProfile?.$id}");
          return null;
        }

        String currentUserName = currentUserProfile.username;
        String otherUserName = otherUserProfile.username;
        
        List<String> participantNames;
        List<String> participantPhotoIds;

        if (participantsArray[0] == currentUserId) {
            participantNames = [currentUserName, otherUserName];
            // CORREGIDO AQUÍ: Acceder a .$id en lugar de .id (aunque profileImageId no es .$id, el error era genérico de .id)
            participantPhotoIds = [currentUserProfile.profileImageId ?? '', otherUserProfile.profileImageId ?? ''];
        } else {
            participantNames = [otherUserName, currentUserName];
            participantPhotoIds = [otherUserProfile.profileImageId ?? '', currentUserProfile.profileImageId ?? ''];
        }

        final newChatDoc = await _databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.chatsCollectionId,
          documentId: ID.unique(),
          data: {
            'participants': participantsArray,
            'participantNames': participantNames,
            'participantPhotoIds': participantPhotoIds,
            'lastMessage': 'Chat iniciado',
            'lastMessageTimestamp': DateTime.now().toIso8601String(),
            if (listingId != null && listingId.isNotEmpty) 'listingId': listingId,
          },
          // permissions: [ ... ], // DESCOMENTA ESTO DESPUÉS DEL DIAGNÓSTICO
        );
        print("[ChatRepository] Nuevo chat creado con ID: ${newChatDoc.$id}");
        return ChatModel.fromJson(newChatDoc.data);
      }
    } catch (e) {
      print("[ChatRepository] EXCEPCIÓN en getOrCreateChat entre $currentUserId y $otherUserId: $e");
      if (e is AppwriteException) {
        print("[ChatRepository] AppwriteException detalle: ${e.message} (Code: ${e.code}, Type: ${e.type})");
      }
      return null;
    }
  }

  Future<List<ChatModel>> getUserChats(String userId) async {
    try {
      print("[ChatRepository] Obteniendo chats para el usuario: $userId");
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chatsCollectionId,
        queries: [
          Query.contains('participants', [userId]), 
          Query.orderDesc('lastMessageTimestamp'),
        ],
      );
      print("[ChatRepository] ${response.documents.length} chats encontrados para el usuario $userId.");
      return response.documents
          .map((doc) => ChatModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      print("[ChatRepository] Error obteniendo chats del usuario $userId: $e");
      if (e is AppwriteException) {
        print("[ChatRepository] AppwriteException: ${e.message} (Code: ${e.code}, Type: ${e.type})");
      }
      rethrow;
    }
  }

  Future<void> updateChatOnNewMessage({
    required String chatId,
    required String lastMessage,
  }) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chatsCollectionId,
        documentId: chatId,
        data: {
          'lastMessage': lastMessage.length > 100 ? '${lastMessage.substring(0,97)}...' : lastMessage,
          'lastMessageTimestamp': DateTime.now().toIso8601String(),
        },
      );
      print("[ChatRepository] Chat $chatId actualizado con el último mensaje.");
    } catch (e) {
      print("[ChatRepository] Error actualizando chat $chatId: $e");
    }
  }
}