// lib/model/user_model.dart
class UserModel {
  final String id; // Corresponde a Appwrite Account $id y document $id en usersCollection
  final String username; // Nombre público para mostrar
  final String email; // Considerar si este campo es necesario para un perfil público
  final String? profileImageId; // ID del archivo de la imagen de perfil en Appwrite Storage

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Si el $id del documento es el ID del usuario, usa json['$id'].
      // Si tienes un campo específico como 'userId', usa json['userId'].
      // Aquí asumimos que el document ID es el user ID.
      id: json['\$id'] ?? json['userId'] ?? '', // Asegúrate de que coincida con tu estructura
      username: json['name'] ?? json['username'] ?? 'Usuario Desconocido', // Prioriza 'name', luego 'username'
      email: json['email'] ?? '', // Puede ser útil, pero considera la privacidad
      profileImageId: json['profileImageId'],
    );
  }

  Map<String, dynamic> toJson() {
    // Este toJson se usaría si crearas/actualizaras documentos en usersCollectionId desde el cliente
    // usando este modelo directamente.
    return {
      // No incluimos 'id' aquí porque usualmente es el ID del documento.
      // 'userId': id, // Si tuvieras un campo 'userId' explícito.
      'name': username, // o 'username' según el atributo en Appwrite
      'email': email,
      if (profileImageId != null) 'profileImageId': profileImageId,
    };
  }
}