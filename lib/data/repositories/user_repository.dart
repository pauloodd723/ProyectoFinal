// lib/data/repositories/user_repository.dart
import 'package:appwrite/appwrite.dart';
import 'package:proyecto_final/core/constants/appwrite_constants.dart';
import 'package:proyecto_final/model/user_model.dart';

class UserRepository {
  final Databases databases;

  UserRepository(this.databases);

  Future<UserModel> createUser(UserModel user) async {
    final response = await databases.createDocument(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.collectionId,
      documentId: ID.unique(),
      data: user.toJson(),
    );
    return UserModel.fromJson(response.data);
  }

  Future<List<UserModel>> getUsers() async {
    final response = await databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.collectionId,
    );
    return response.documents
        .map((doc) => UserModel.fromJson(doc.data))
        .toList();
  }

  // Métodos delete y update también, si los necesitas
}
