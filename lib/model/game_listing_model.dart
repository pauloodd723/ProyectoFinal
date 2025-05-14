// lib/models/game_listing_model.dart // Si usaras Timestamp, sino puedes quitarlo. Appwrite usa Strings para fechas.

class GameListingModel {
  final String id; // Document ID de Appwrite ($id)
  final String title;
  final double price;
  final String sellerName;
  final String sellerId;
  final String? imageUrl;
  final String? description;
  final String? gameCondition;
  final String status;
  final DateTime? createdAt; // Appwrite usa $createdAt (String)

  GameListingModel({
    required this.id,
    required this.title,
    required this.price,
    required this.sellerName,
    required this.sellerId,
    this.imageUrl,
    this.description,
    this.gameCondition,
    this.status = 'disponible',
    this.createdAt,
  });

  factory GameListingModel.fromJson(Map<String, dynamic> json) {
    return GameListingModel(
      id: json['\$id'], // ID del documento de Appwrite
      title: json['title'],
      price: (json['price'] as num).toDouble(), // Asegurar que sea double
      sellerName: json['sellerName'],
      sellerId: json['sellerId'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      gameCondition: json['gameCondition'],
      status: json['status'] ?? 'disponible',
      createdAt: json['\$createdAt'] != null
          ? DateTime.tryParse(json['\$createdAt']) // Appwrite devuelve fechas como String ISO 8601
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'price': price,
      'sellerName': sellerName,
      'sellerId': sellerId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (description != null) 'description': description,
      if (gameCondition != null) 'gameCondition': gameCondition,
      'status': status,
      // No incluimos id ni createdAt en toJson para creación, Appwrite los maneja.
    };
  }
}