// lib/data/repositories/game_listing_repository.dart
import 'package:appwrite/appwrite.dart';
import 'package:proyecto_final/core/constants/appwrite_constants.dart';
import 'package:proyecto_final/model/game_listing_model.dart';

class GameListingRepository {
  final Databases databases;

  GameListingRepository(this.databases);

  Future<List<GameListingModel>> getGameListings({String? searchQuery}) async {
    try {
      List<String>? queries;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Búsqueda simple por título. Appwrite puede necesitar índices para búsquedas eficientes.
        // Para búsqueda por vendedor, necesitarías otro query o una lógica más compleja.
        queries = [Query.search('title', searchQuery)];
      }

      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.gameListingsCollectionId,
        queries: queries, // Añadir queries para búsqueda
      );
      return response.documents
          .map((doc) => GameListingModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      print("Error en GameListingRepository.getGameListings: $e");
      rethrow;
    }
  }

  Future<GameListingModel> addGameListing(GameListingModel listing, String userId) async {
    // userId es el ID del usuario actualmente logueado, que será el sellerId
    try {
      final response = await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.gameListingsCollectionId,
        documentId: ID.unique(),
        data: listing.copyWith(sellerId: userId).toJson(), // Asegura que sellerId esté en los datos
        permissions: [
          Permission.read(Role.any()), // Cualquiera puede leer
          Permission.update(Role.user(userId)), // Solo el creador puede actualizar
          Permission.delete(Role.user(userId)), // Solo el creador puede borrar
        ],
      );
      return GameListingModel.fromJson(response.data);
    } catch (e) {
      print("Error en GameListingRepository.addGameListing: $e");
      rethrow;
    }
  }
}

// Extensión para GameListingModel si necesitas `copyWith` (opcional pero útil)
extension GameListingModelCopyWith on GameListingModel {
  GameListingModel copyWith({
    String? id,
    String? title,
    double? price,
    String? sellerName,
    String? sellerId,
    String? imageUrl,
    String? description,
    String? gameCondition,
    String? status,
    DateTime? createdAt,
  }) {
    return GameListingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      sellerName: sellerName ?? this.sellerName,
      sellerId: sellerId ?? this.sellerId,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      gameCondition: gameCondition ?? this.gameCondition,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}