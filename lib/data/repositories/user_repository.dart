// lib/data/repositories/user_repository.dart
import 'package:appwrite/appwrite.dart';
import 'package:proyecto_final/core/constants/appwrite_constants.dart';
import 'package:proyecto_final/model/user_model.dart'; // Asegúrate de que el path sea correcto

class UserRepository {
  final Databases databases;

  UserRepository(this.databases);

  Future<UserModel> createUser(UserModel user) async {
    final response = await databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.usersCollectionId, // CORREGIDO: Usar usersCollectionId
      documentId: ID.unique(),
      data: user.toJson(),
    );
    return UserModel.fromJson(response.data);
  }

  Future<List<UserModel>> getUsers() async {
    final response = await databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.usersCollectionId, // CORREGIDO: Usar usersCollectionId
    );
    return response.documents
        .map((doc) => UserModel.fromJson(doc.data))
        .toList();
  }

  // Puedes añadir métodos para actualizar y eliminar usuarios si es necesario.
  // Future<UserModel> updateUser(String userId, Map<String, dynamic> data) async { ... }
  // Future<void> deleteUser(String userId) async { ... }
}
