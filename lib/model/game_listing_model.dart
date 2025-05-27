import 'package:proyecto_final/core/constants/appwrite_constants.dart';

class GameListingModel {
  final String id;
  final String title;
  final double price;
  final String sellerName;
  final String sellerId;
  final String? imageUrl;
  final String? description;
  final String? gameCondition;
  final String status; 
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? _constructedDisplayImageUrl;

  GameListingModel({
    required this.id,
    required this.title,
    required this.price,
    required this.sellerName,
    required this.sellerId,
    this.imageUrl,
    this.description,
    this.gameCondition,
    this.status = 'available', 
    this.createdAt,
    this.updatedAt,
  });

  factory GameListingModel.fromJson(Map<String, dynamic> json) {
    return GameListingModel(
      id: json['\$id'],
      title: json['title'],
      price: (json['price'] as num).toDouble(),
      sellerName: json['sellerName'],
      sellerId: json['sellerId'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      gameCondition: json['gameCondition'],
      status: json['status'] ?? 'available',
      createdAt: json['\$createdAt'] != null
          ? DateTime.tryParse(json['\$createdAt'])
          : null,
      updatedAt: json['\$updatedAt'] != null
          ? DateTime.tryParse(json['\$updatedAt'])
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
    };
  }

  String? getDisplayImageUrl() {
    print("--- [GameListingModel.getDisplayImageUrl] DEBUG ---");
    print("Intentando obtener URL para el objeto con título: '${this.title}'");
    print("Valor actual de this.imageUrl (debería ser un File ID): '${this.imageUrl}'");
    print("----------------------------------------------------");

    if (_constructedDisplayImageUrl != null) {
      print("[GameListingModel.getDisplayImageUrl] Devolviendo URL cacheada: $_constructedDisplayImageUrl");
      return _constructedDisplayImageUrl;
    }

    if (this.imageUrl == null || this.imageUrl!.isEmpty) {
      print("[GameListingModel.getDisplayImageUrl] this.imageUrl es null o vacío. No se puede construir URL.");
      return null;
    }

    try {
      List<String> queryParams = ['project=${AppwriteConstants.projectId}'];
      
      String constructedUrl =
          "${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.gameImagesBucketId}/files/${this.imageUrl}/view?${queryParams.join('&')}";
      
      if (constructedUrl.endsWith('&')) {
        constructedUrl = constructedUrl.substring(0, constructedUrl.length -1);
      }
        if (!constructedUrl.contains('?')) { 
                constructedUrl = constructedUrl.replaceFirst('&', '?');
      }

      _constructedDisplayImageUrl = constructedUrl;
      
      print("[GameListingModel.getDisplayImageUrl] URL con /view de Appwrite construida: $_constructedDisplayImageUrl");
      return _constructedDisplayImageUrl;

    } catch (e) {
      print("[GameListingModel.getDisplayImageUrl] Error construyendo URL con /view para File ID ${this.imageUrl}: $e");
      return null;
    }
  }


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
    DateTime? updatedAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}