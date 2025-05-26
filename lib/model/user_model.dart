// lib/model/user_model.dart
class UserModel {
  final String $id;
  final String username;
  final String email;
  final String? profileImageId;
  final String? defaultAddress;
  final double? latitude;    // Asegúrate que esto esté aquí
  final double? longitude;   // Asegúrate que esto esté aquí

  UserModel({
    required this.$id,
    required this.username,
    required this.email,
    this.profileImageId,
    this.defaultAddress,
    this.latitude,         // Y aquí
    this.longitude,        // Y aquí
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      $id: json['\$id'] as String, // Asume que $id está en el mapa
      username: json['name'] as String, // o json['username'] según tu BD
      email: json['email'] as String,
      profileImageId: json['profileImageId'] as String?,
      defaultAddress: json['defaultAddress'] as String?,
      // Correcta extracción de lat/lon, manejando nulls y conversión de num
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': username, // o 'username'
      'email': email,
      if (profileImageId != null) 'profileImageId': profileImageId,
      'defaultAddress': defaultAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  UserModel copyWith({
    String? $id,
    String? username,
    String? email,
    String? profileImageId,
    bool allowNullProfileImageId = false,
    String? defaultAddress,
    bool allowNullDefaultAddress = false,
    double? latitude,
    bool allowNullLatitude = false, // Para permitir establecer explícitamente a null
    double? longitude,
    bool allowNullLongitude = false, // Para permitir establecer explícitamente a null
  }) {
    return UserModel(
      $id: $id ?? this.$id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageId: allowNullProfileImageId ? profileImageId : (profileImageId ?? this.profileImageId),
      defaultAddress: allowNullDefaultAddress ? defaultAddress : (defaultAddress ?? this.defaultAddress),
      latitude: allowNullLatitude ? latitude : (latitude ?? this.latitude),
      longitude: allowNullLongitude ? longitude : (longitude ?? this.longitude),
    );
  }
}