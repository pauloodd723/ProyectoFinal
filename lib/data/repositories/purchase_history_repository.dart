import 'package:appwrite/appwrite.dart';
import 'package:proyecto_final/core/constants/appwrite_constants.dart';
import 'package:proyecto_final/model/purchase_history_model.dart';

class PurchaseHistoryRepository {
  final Databases _databases;

  PurchaseHistoryRepository(this._databases);

  Future<void> createPurchaseRecord({
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String listingId,
    required String listingTitle,
    required double pricePaid,
    String? couponIdUsed,
    double? discountApplied,
  }) async {
    try {
      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.purchaseHistoryCollectionId,
        documentId: ID.unique(),
        data: {
          'buyerId': buyerId,
          'buyerName': buyerName,
          'sellerId': sellerId,
          'listingId': listingId,
          'listingTitle': listingTitle,
          'pricePaid': pricePaid,
          if (couponIdUsed != null) 'couponIdUsed': couponIdUsed,
          'discountApplied': discountApplied ?? 0.0, 
        },
      );
      print("[PurchaseHistoryRepository] Registro de compra creado para el comprador $buyerId, juego $listingTitle.");
    } catch (e) {
      print("[PurchaseHistoryRepository] Error creando registro de compra: $e");
      rethrow;
    }
  }

  Future<List<PurchaseHistoryModel>> getPurchasesByBuyer(String buyerId, {int limit = 25, int offset = 0}) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.purchaseHistoryCollectionId,
        queries: [
          Query.equal('buyerId', buyerId),
          Query.orderDesc('\$createdAt'),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );
      return response.documents
          .map((doc) => PurchaseHistoryModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      print("[PurchaseHistoryRepository] Error obteniendo compras por comprador $buyerId: $e");
      rethrow;
    }
  }

  Future<List<PurchaseHistoryModel>> getSalesBySeller(String sellerId, {int limit = 25, int offset = 0}) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.purchaseHistoryCollectionId,
        queries: [
          Query.equal('sellerId', sellerId),
          Query.orderDesc('\$createdAt'),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );
      return response.documents
          .map((doc) => PurchaseHistoryModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      print("[PurchaseHistoryRepository] Error obteniendo ventas por vendedor $sellerId: $e");
      rethrow;
    }
  }
}