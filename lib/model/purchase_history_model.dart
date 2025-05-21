// lib/model/purchase_history_model.dart

class PurchaseHistoryModel {
  final String id; // $id del documento de Appwrite
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String listingId;
  final String listingTitle;
  final double pricePaid;
  final String? couponIdUsed;
  final double? discountApplied;
  final DateTime purchaseDate; // Se parseará desde Appwrite $createdAt

  PurchaseHistoryModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.listingId,
    required this.listingTitle,
    required this.pricePaid,
    this.couponIdUsed,
    this.discountApplied,
    required this.purchaseDate,
  });

  factory PurchaseHistoryModel.fromJson(Map<String, dynamic> json) {
    return PurchaseHistoryModel(
      id: json['\$id'],
      buyerId: json['buyerId'],
      buyerName: json['buyerName'],
      sellerId: json['sellerId'],
      listingId: json['listingId'],
      listingTitle: json['listingTitle'],
      pricePaid: (json['pricePaid'] as num).toDouble(),
      couponIdUsed: json['couponIdUsed'],
      discountApplied: (json['discountApplied'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'])
          : DateTime.now(), // Fallback
    );
  }

  // No necesitamos toJson() si la creación se maneja directamente en el repositorio
  // con un mapa, pero es bueno tenerlo por completitud.
  Map<String, dynamic> toJson() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'pricePaid': pricePaid,
      if (couponIdUsed != null) 'couponIdUsed': couponIdUsed,
      if (discountApplied != null) 'discountApplied': discountApplied,
      // $createdAt y $id son manejados por Appwrite
    };
  }
}