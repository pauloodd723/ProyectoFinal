import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:proyecto_final/core/constants/appwrite_constants.dart';
import 'package:proyecto_final/model/game_listing_model.dart';

enum PriceSortOption { none, lowestFirst, highestFirst }

class GameListingRepository {
  final Databases databases;
  final Storage storage;

  GameListingRepository(this.databases, this.storage);

  Future<String?> uploadGameImage(File imageFile, String userId) async {
    try {
      final fileName =
          'game_${userId}_${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
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
      print("Error en GameListingRepository.uploadGameImage: $e");
      if (e is AppwriteException) {
        print(
            "[GameListingRepo] AppwriteException (upload): Code: ${e.code}, Message: ${e.message}, Type: ${e.type}");
      }
      rethrow;
    }
  }

  Future<void> deleteGameImage(String fileIdToDelete) async {
    if (fileIdToDelete.isEmpty) return;
    try {
      await storage.deleteFile(
        bucketId: AppwriteConstants.gameImagesBucketId,
        fileId: fileIdToDelete,
      );
      print("Imagen $fileIdToDelete eliminada de Storage.");
    } catch (e) {
      if (e is AppwriteException && e.code == 404) {
        print(
            "Error en GameListingRepository.deleteGameImage: Imagen $fileIdToDelete no encontrada. $e");
      } else {
        print(
            "Error en GameListingRepository.deleteGameImage ($fileIdToDelete): $e");
        if (e is AppwriteException) {
          print(
              "[GameListingRepo] AppwriteException (deleteImg): Code: ${e.code}, Message: ${e.message}, Type: ${e.type}");
        }
        rethrow;
      }
    }
  }

  Future<List<GameListingModel>> getGameListings(
      {String? searchQuery,
      PriceSortOption sortOption = PriceSortOption.none,
      String? sellerId 
      }) async {
    try {
      List<String> queries = [];

      if (sellerId != null && sellerId.isNotEmpty) {
        queries.add(Query.equal('sellerId', sellerId));
      }

      if (sortOption == PriceSortOption.none && (sellerId == null || sellerId.isEmpty)) {
        queries.add(Query.orderDesc('\$createdAt'));
      } else if (sortOption == PriceSortOption.none && sellerId != null && sellerId.isNotEmpty) {
         queries.add(Query.orderDesc('\$createdAt'));
      }


      if (searchQuery != null && searchQuery.isNotEmpty) {
        queries.add(Query.search('title', searchQuery));
      }

      if (sortOption == PriceSortOption.lowestFirst) {
        queries.add(Query.orderAsc('price'));
      } else if (sortOption == PriceSortOption.highestFirst) {
        queries.add(Query.orderDesc('price'));
      }
      if (sellerId == null || sellerId.isEmpty) { 
      }

      print("[GameListingRepo.getGameListings] Queries for sellerId '$sellerId': $queries");

      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.gameListingsCollectionId,
        queries: queries.isNotEmpty ? queries : null, 
      );
      return response.documents
          .map((doc) => GameListingModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      print("Error en GameListingRepository.getGameListings: $e");
      if (e is AppwriteException) {
        print(
            "[GameListingRepo] AppwriteException (getListings): Code: ${e.code}, Message: ${e.message}, Type: ${e.type}");
      }
      rethrow;
    }
  }

  Future<GameListingModel> addGameListing(
      GameListingModel listingData, String userId,
      {String? uploadedFileId}) async {
    try {
      final Map<String, dynamic> dataForDb = listingData
          .copyWith(
            sellerId: userId,
            imageUrl: uploadedFileId,
            status: 'available' 
          )
          .toJson();

      if (uploadedFileId == null && dataForDb['imageUrl'] == null) {
        print(
            "[GameListingRepo.addGameListing] ADVERTENCIA: uploadedFileId es null. Si 'imageUrl' es requerido en BD, esto fallará.");
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
      String documentId, Map<String, dynamic> dataToUpdate, String userId,
      {String? newUploadedFileId, String? oldFileId}) async {
    try {
      if (newUploadedFileId != null &&
          oldFileId != null &&
          newUploadedFileId != oldFileId) {
        await deleteGameImage(oldFileId);
      }
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

  Future<void> deleteGameListing(
      String documentId, String? fileIdInDocument) async {
    try {
      if (fileIdInDocument != null && fileIdInDocument.isNotEmpty) {
        await deleteGameImage(fileIdInDocument);
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

  String getFilePreviewUrl(String fileIdToPreview) {
    if (fileIdToPreview.isEmpty) {
      print("[GameListingRepo.getFilePreviewUrl] No fileIdToPreview provided.");
      return '';
    }

    try {
      List<String> queryParams = ['project=${AppwriteConstants.projectId}'];

      String constructedUrl =
          "${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.gameImagesBucketId}/files/$fileIdToPreview/preview?${queryParams.join('&')}";

      if (constructedUrl.endsWith('&')) {
        constructedUrl = constructedUrl.substring(0, constructedUrl.length - 1);
      }
      if (!constructedUrl.contains('?')) {
        constructedUrl = constructedUrl.replaceFirst('&', '?');
      }

      print(
          "[GameListingRepo.getFilePreviewUrl] Constructed URL for $fileIdToPreview: $constructedUrl");
      return constructedUrl;
    } catch (e) {
      print(
          "[GameListingRepo.getFilePreviewUrl] Error constructing URL for $fileIdToPreview: $e");
      return '';
    }
  }

  Future<void> updateListingSellerName(String documentId, String newSellerName) async {
    try {
      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.gameListingsCollectionId,
        documentId: documentId,
        data: {'sellerName': newSellerName},
      );
      print("[GameListingRepo.updateListingSellerName] Updated sellerName for doc $documentId to $newSellerName");
    } catch (e) {
      print("Error en GameListingRepository.updateListingSellerName for doc $documentId: $e");
      rethrow; 
    }
  }

  Future<List<GameListingModel>> getSoldListingsByUser(String sellerId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.gameListingsCollectionId,
        queries: [
          Query.equal('sellerId', sellerId),
          Query.equal('status', 'sold'),
          Query.orderDesc('\$updatedAt') 
        ],
      );
      return response.documents
          .map((doc) => GameListingModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      print("Error en GameListingRepository.getSoldListingsByUser: $e");
      rethrow;
    }
  }
}