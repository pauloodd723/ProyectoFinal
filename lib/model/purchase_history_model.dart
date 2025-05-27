class PurchaseHistoryModel {
  final String id; 
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String listingId;
  final String listingTitle;
  final double pricePaid;
  final String? couponIdUsed;
  final double? discountApplied;
  final DateTime purchaseDate;

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
          : DateTime.now(), 
    );
  }

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
    };
  }
}