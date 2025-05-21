// lib/data/repositories/auth_repository.dart
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models; // Asegúrate que 'as appwrite_models' esté si lo usas así en AuthController
import 'package:proyecto_final/core/constants/appwrite_constants.dart';

class AuthRepository {
  final Account account;
  final Storage storage;

  AuthRepository(this.account, this.storage);

  // VERIFICA ESTE MÉTODO CUIDADOSAMENTE
  Future<appwrite_models.User> createAccount({ // 1. DEBE DEVOLVER Future<appwrite_models.User>
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 2. DEBE TENER 'return await' aquí
      return await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
    } catch (e) {
      print("Error en AuthRepository.createAccount: $e");
      // Si el error es de Appwrite, como "user already exists" o "password too short",
      // este rethrow lo enviará al AuthController para ser manejado.
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      await account.get();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<appwrite_models.User> updateUserName(String newName) async {
    try {
      return await account.updateName(name: newName);
    } catch (e) {
      print("Error en AuthRepository.updateUserName: $e");
      rethrow;
    }
  }

  Future<String?> uploadProfilePicture(File imageFile, String userId) async {
    try {
      final fileName = 'user_profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
      final inputFile = InputFile.fromPath(
        path: imageFile.path,
        filename: fileName,
      );

      final appwrite_models.File responseFile = await storage.createFile(
        bucketId: AppwriteConstants.gameImagesBucketId,
        fileId: ID.unique(),
        file: inputFile,
        permissions: [
          Permission.read(Role.any()),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );
      return responseFile.$id;
    } catch (e) {
      print("Error en AuthRepository.uploadProfilePicture: $e");
      if (e is AppwriteException) {
        print("[AuthRepo] AppwriteException (uploadProfilePic): Code: ${e.code}, Message: ${e.message}, Type: ${e.type}");
      }
      rethrow;
    }
  }
  
  Future<void> deleteProfilePicture(String fileId) async {
    if (fileId.isEmpty) return;
    try {
      await storage.deleteFile(
        bucketId: AppwriteConstants.gameImagesBucketId,
        fileId: fileId,
      );
      print("Foto de perfil $fileId eliminada de Storage (bucket: ${AppwriteConstants.gameImagesBucketId}).");
    } catch (e) {
      if (e is AppwriteException && e.code == 404) {
        print("Error en AuthRepository.deleteProfilePicture: Imagen $fileId no encontrada. $e");
      } else {
        print("Error en AuthRepository.deleteProfilePicture ($fileId): $e");
        rethrow;
      }
    }
  }

  Future<appwrite_models.User> updateUserPrefs(Map<String, dynamic> prefs) async {
    try {
      return await account.updatePrefs(prefs: prefs);
    } catch (e) {
      print("Error en AuthRepository.updateUserPrefs: $e");
      rethrow;
    }
  }

  String getProfilePictureUrl(String fileId) {
    if (fileId.isEmpty) {
      return "https://placehold.co/150x150/7F00FF/FFFFFF?text=Perfil";
    }
    try {
      List<String> queryParams = ['project=${AppwriteConstants.projectId}'];
      
      String constructedUrl =
          "${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.gameImagesBucketId}/files/$fileId/view?${queryParams.join('&')}";
      
      if (constructedUrl.endsWith('&')) {
        constructedUrl = constructedUrl.substring(0, constructedUrl.length -1);
      }
      if (!constructedUrl.contains('?')) {
             constructedUrl = constructedUrl.replaceFirst('&', '?');
      }
      print("[AuthRepository.getProfilePictureUrl] Constructed URL (using /view) for $fileId: $constructedUrl");
      return constructedUrl;
    } catch (e) {
      print("[AuthRepository.getProfilePictureUrl] Error construyendo URL para $fileId: $e");
      return "https://placehold.co/150x150/E0E0E0/B0B0B0?text=Error";
    }
  }
}