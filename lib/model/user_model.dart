class UserModel {
  final String $id;
  final String username;
  final String email;
  final String? profileImageId;
  final String? defaultAddress;
  final double? latitude;  
  final double? longitude; 

  UserModel({
    required this.$id,
    required this.username,
    required this.email,
    this.profileImageId,
    this.defaultAddress,
    this.latitude,     
    this.longitude,     
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      $id: json['\$id'] as String, 
      username: json['name'] as String, 
      email: json['email'] as String,
      profileImageId: json['profileImageId'] as String?,
      defaultAddress: json['defaultAddress'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': username, 
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
    bool allowNullLatitude = false, 
    double? longitude,
    bool allowNullLongitude = false, 
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