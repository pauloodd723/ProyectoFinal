// lib/data/repositories/game_listing_repository.dart
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:proyecto_final/core/constants/appwrite_constants.dart';
import 'package:proyecto_final/model/game_listing_model.dart';

class GameListingRepository {
  final Databases databases;
  final Storage storage;

  GameListingRepository(this.databases, this.storage);

  Future<String?> uploadGameImage(File imageFile, String userId) async {
    try {
      final fileName = 'game_${userId}_${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
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
      return responseFile.$id; // Este es el ID del archivo que se guardará en el campo 'imageUrl' del documento
    } catch (e) {
      print("Error en GameListingRepository.uploadGameImage: $e");
      if (e is AppwriteException) {
        print("[GameListingRepo] AppwriteException (upload): Code: ${e.code}, Message: ${e.message}, Type: ${e.type}");
      }
      rethrow;
    }
  }

  Future<void> deleteGameImage(String fileIdToDelete) async { // Renombrado parámetro para claridad
    if (fileIdToDelete.isEmpty) return;
    try {
      await storage.deleteFile(
        bucketId: AppwriteConstants.gameImagesBucketId,
        fileId: fileIdToDelete,
      );
      print("Imagen $fileIdToDelete eliminada de Storage.");
    } catch (e) {
      // ... (manejo de errores sin cambios)
      if (e is AppwriteException && e.code == 404) {
        print("Error en GameListingRepository.deleteGameImage: Imagen $fileIdToDelete no encontrada. $e");
      } else {
        print("Error en GameListingRepository.deleteGameImage ($fileIdToDelete): $e");
        if (e is AppwriteException) {
          print("[GameListingRepo] AppwriteException (deleteImg): Code: ${e.code}, Message: ${e.message}, Type: ${e.type}");
        }
        rethrow;
      }
    }
  }

  Future<List<GameListingModel>> getGameListings({String? searchQuery}) async {
    // ... (sin cambios en la lógica interna)
    try {
      List<String> queries = [Query.orderDesc('\$createdAt')];
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queries.add(Query.search('title', searchQuery));
      }

      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.gameListingsCollectionId,
        queries: queries,
      );
      return response.documents
          .map((doc) => GameListingModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      print("Error en GameListingRepository.getGameListings: $e");
      rethrow;
    }
  }

  // ACTUALIZADO: El parámetro 'uploadedFileId' se usará para el campo 'imageUrl' del modelo
  Future<GameListingModel> addGameListing(GameListingModel listingData, String userId, {String? uploadedFileId}) async {
    try {
      final Map<String, dynamic> dataForDb = listingData.copyWith(
        sellerId: userId,
        imageUrl: uploadedFileId // Asigna el ID del archivo subido al campo 'imageUrl' del modelo
      ).toJson();

      // Asegurarse de que 'imageUrl' se envíe si es requerido y uploadedFileId es null
      // Si 'imageUrl' es requerido en Appwrite y uploadedFileId es null (no se subió imagen),
      // esto fallará a menos que la colección permita que 'imageUrl' sea null.
      // El error actual indica que 'imageUrl' es requerido.
      if (uploadedFileId == null && dataForDb['imageUrl'] == null) {
          // Si el campo 'imageUrl' es requerido en Appwrite, y no tenemos un ID de archivo,
          // esta operación fallará. El modelo de error lo indica.
          // Se podría lanzar un error aquí o dejar que Appwrite lo haga.
          print("[GameListingRepo.addGameListing] ADVERTENCIA: uploadedFileId es null. Si 'imageUrl' es requerido en BD, esto fallará.");
      }


      final response = await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.gameListingsCollectionId,
        documentId: ID.unique(),
        data: dataForDb,
        permissions: [
          Permission.read(Role.any()),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );
      return GameListingModel.fromJson(response.data);
    } catch (e) {
      print("Error en GameListingRepository.addGameListing: $e");
      rethrow;
    }
  }

  Future<GameListingModel> updateGameListing(
    String documentId,
    Map<String, dynamic> dataToUpdate, // Esto ya debería tener 'imageUrl' si se cambió
    String userId, {
    String? newUploadedFileId, // ID del archivo nuevo si se subió uno
    String? oldFileId // ID del archivo antiguo para borrarlo
  }) async {
    try {
      // Si se subió una nueva imagen (newUploadedFileId no es null)
      // Y había una imagen antigua (oldFileId no es null)
      // Y son diferentes
      if (newUploadedFileId != null && oldFileId != null && newUploadedFileId != oldFileId) {
        await deleteGameImage(oldFileId);
      }
      // dataToUpdate ya debería contener el campo 'imageUrl' con el 'newUploadedFileId'
      // o con null si se eliminó la imagen sin reemplazarla,
      // o con el 'oldFileId' si no se cambió la imagen.
      // Esto se maneja en el GameListingController.

      final response = await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.gameListingsCollectionId,
        documentId: documentId,
        data: dataToUpdate,
      );
      return GameListingModel.fromJson(response.data);
    } catch (e) {
      print("Error en GameListingRepository.updateGameListing: $e");
      rethrow;
    }
  }

  // ACTUALIZADO: el parámetro 'fileIdInDocument' ahora se refiere al campo 'imageUrl' del listado.
  Future<void> deleteGameListing(String documentId, String? fileIdInDocument) async {
    try {
      if (fileIdInDocument != null && fileIdInDocument.isNotEmpty) {
        await deleteGameImage(fileIdInDocument); // Usa el ID del archivo almacenado en el documento
      }
      await databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.gameListingsCollectionId,
        documentId: documentId,
      );
    } catch (e) {
      print("Error en GameListingRepository.deleteGameListing: $e");
      rethrow;
    }
  }

  // Este método ahora es síncrono y construye la URL.
  String getFilePreviewUrl(String fileIdToPreview, {int? width, int? height, int? quality = 75}) {
    if (fileIdToPreview.isEmpty) {
      print("[GameListingRepo.getFilePreviewUrl] No fileIdToPreview provided.");
      return '';
    }
    
    try {
      List<String> queryParams = ['project=${AppwriteConstants.projectId}'];
      if (width != null) queryParams.add('width=$width');
      if (height != null) queryParams.add('height=$height');
      if (quality != null && quality >= 0 && quality <= 100) queryParams.add('quality=$quality');

      final String constructedUrl =
          "${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.gameImagesBucketId}/files/$fileIdToPreview/preview?${queryParams.join('&')}";
      
      print("[GameListingRepo.getFilePreviewUrl] Constructed URL for $fileIdToPreview: $constructedUrl");
      return constructedUrl;

    } catch (e) {
      print("[GameListingRepo.getFilePreviewUrl] Error constructing URL for $fileIdToPreview: $e");
      return '';
    }
  }
}
