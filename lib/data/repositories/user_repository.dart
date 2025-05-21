// lib/data/repositories/user_repository.dart
import 'package:appwrite/appwrite.dart';
import 'package:proyecto_final/core/constants/appwrite_constants.dart';
import 'package:proyecto_final/model/user_model.dart';

class UserRepository {
  final Databases databases;
  // Quitamos Account y Storage de aquí, la URL de la imagen se puede construir en el UserController o Widget
  // si el UserModel tiene el profileImageId.

  UserRepository(this.databases);

  Future<UserModel?> getUserById(String userId) async {
    try {
      print("[UserRepository.getUserById] Fetching user document for ID: $userId from collection ${AppwriteConstants.usersCollectionId}");
      final userDocument = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: userId, // Asumimos que el ID del documento es el ID de la cuenta del usuario
      );
      print("[UserRepository.getUserById] User document data: ${userDocument.data}");
      // Aquí, estamos usando el $id del documento como el 'id' del UserModel
      return UserModel.fromJson(userDocument.data..['\$id'] = userDocument.$id);
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        print("[UserRepository.getUserById] User with ID $userId not found in collection ${AppwriteConstants.usersCollectionId}. Error: ${e.message}");
        return null; // Usuario no encontrado en la colección de perfiles públicos
      }
      print("[UserRepository.getUserById] AppwriteException fetching user $userId: ${e.message} (Code: ${e.code})");
      rethrow;
    } catch (e) {
      print("[UserRepository.getUserById] General error fetching user $userId: $e");
      rethrow;
    }
  }

  Future<UserModel> createOrUpdatePublicUserProfile({
    required String userId,
    required String name,
    required String email,
    String? profileImageId, // Este es el File ID de la imagen en Appwrite Storage
  }) async {
    Map<String, dynamic> data = {
      'name': name, // Asegúrate que este atributo exista en tu colección 'usersCollectionId'
      'email': email, // Considera la privacidad de este campo
      // Solo incluye profileImageId si no es null. Si es null y quieres borrarlo del doc, envía null.
      // Si quieres que no se toque si es null, no lo incluyas en el mapa 'data'.
      // Para este caso, lo actualizaremos o lo pondremos si existe.
    };
    if (profileImageId != null) {
      data['profileImageId'] = profileImageId;
    } else {
      // Si profileImageId es explícitamente null (ej. el usuario eliminó su foto)
      // y quieres reflejar esto en el perfil público, puedes enviar null.
      // O puedes decidir no enviar el campo si no quieres que se actualice a null.
      // Por ahora, si es null, no lo enviamos para evitar borrarlo si no se proporciona.
      // Si quieres permitir borrarlo, envía: data['profileImageId'] = null; (pero Appwrite podría no permitir nulls si no está configurado)
      // O mejor, no incluyas la clave si es null y no quieres actualizarlo.
      // Si el atributo 'profileImageId' puede ser null en Appwrite:
       data['profileImageId'] = null; // O la lógica que prefieras
    }


    try {
      print("[UserRepository.createOrUpdatePublicUserProfile] Updating document for user $userId in ${AppwriteConstants.usersCollectionId}");
      final userDoc = await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: userId,
        data: data,
      );
      return UserModel.fromJson(userDoc.data..['\$id'] = userDoc.$id);
    } on AppwriteException catch (e) {
      if (e.code == 404) { // Document not found, so create it
        print("[UserRepository.createOrUpdatePublicUserProfile] Document for user $userId not found. Creating...");
        final userDoc = await databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollectionId,
          documentId: userId, // Usar el ID de la cuenta como ID del documento
          data: data,
          permissions: [Permission.read(Role.any())], // Lectura pública para el perfil
        );
        return UserModel.fromJson(userDoc.data..['\$id'] = userDoc.$id);
      }
      print("[UserRepository.createOrUpdatePublicUserProfile] AppwriteException for user $userId: ${e.message}");
      rethrow;
    } catch (e) {
      print("[UserRepository.createOrUpdatePublicUserProfile] General error for user $userId: $e");
      rethrow;
    }
  }

  // Este método 'createUser' podría ser redundante si createOrUpdatePublicUserProfile
  // se llama después del registro a través de AuthController.
  // Lo dejo por si lo usas en otro lado, pero asegúrate de su propósito.
  Future<UserModel> createUser(UserModel user) async {
    // Asegúrate que el toJson() de UserModel coincida con los atributos de tu colección.
    // Y que user.id sea el ID de la cuenta de Appwrite.
    print("[UserRepository.createUser] Creating user document for ID: ${user.id}");
    final response = await databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.usersCollectionId,
      documentId: user.id, // Usar el ID de la cuenta como ID del documento
      data: user.toJson(), // Esto debería incluir 'name', 'email', 'profileImageId'
      permissions: [Permission.read(Role.any())],
    );
    return UserModel.fromJson(response.data..['\$id'] = response.$id);
  }

  Future<List<UserModel>> getUsers() async {
    // Este método obtiene todos los perfiles públicos.
    print("[UserRepository.getUsers] Fetching all users from ${AppwriteConstants.usersCollectionId}");
    final response = await databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.usersCollectionId,
    );
    return response.documents
        .map((doc) => UserModel.fromJson(doc.data..['\$id'] = doc.$id))
        .toList();
  }
}