import 'package:appwrite/appwrite.dart';
import 'package:proyecto_final/core/constants/appwrite_constants.dart';
import 'package:proyecto_final/model/user_model.dart';

class UserRepository {
  final Databases databases;

  UserRepository(this.databases);

  Future<UserModel?> getUserById(String userId) async {
    try {
      print(
          "[UserRepository.getUserById] Fetching user document for ID: $userId from collection ${AppwriteConstants.usersCollectionId}");
      final userDocument = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: userId,
      );
      print(
          "[UserRepository.getUserById] User document data: ${userDocument.data}");

      final data = Map<String, dynamic>.from(userDocument.data);
      data['\$id'] = userDocument.$id; 
      return UserModel.fromJson(data);
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        print(
            "[UserRepository.getUserById] User with ID $userId not found in collection ${AppwriteConstants.usersCollectionId}. Error: ${e.message}");
        return null;
      }
      print(
          "[UserRepository.getUserById] AppwriteException fetching user $userId: ${e.message} (Code: ${e.code})");
      rethrow;
    } catch (e) {
      print("[UserRepository.getUserById] General error fetching user $userId: $e");
      rethrow;
    }
  }

  Future<UserModel> createOrUpdatePublicUserProfile({
    required String userId,
    required String name,
    required String email,
    String? profileImageId,
    String? defaultAddress,
    double? latitude,    
    double? longitude,   
  }) async {
    Map<String, dynamic> dataPayload = {
      'name': name,
      'email': email,
      'defaultAddress': defaultAddress,
      'latitude': latitude,       
      'longitude': longitude,    
      'profileImageId': profileImageId,
    };

    try {
      print(
          "[UserRepository.createOrUpdatePublicUserProfile] Updating/Creating document for user $userId with payload: $dataPayload");
      final userDoc = await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: userId,
        data: dataPayload,
      );
      final docData = Map<String, dynamic>.from(userDoc.data);
      docData['\$id'] = userDoc.$id;
      return UserModel.fromJson(docData);
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        print(
            "[UserRepository.createOrUpdatePublicUserProfile] Document for user $userId not found. Creating...");
        final userDoc = await databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollectionId,
          documentId: userId,
          data: dataPayload,
          permissions: [Permission.read(Role.any())],
        );
        final docData = Map<String, dynamic>.from(userDoc.data);
        docData['\$id'] = userDoc.$id;
        return UserModel.fromJson(docData);
      }
      print(
          "[UserRepository.createOrUpdatePublicUserProfile] AppwriteException for user $userId: ${e.message}");
      rethrow;
    } catch (e) {
      print(
          "[UserRepository.createOrUpdatePublicUserProfile] General error for user $userId: $e");
      rethrow;
    }
  }

  Future<UserModel?> updateUserLocationData({
    required String userId,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      print(
          "[UserRepository] updateUserLocationData para $userId: Addr: $address, Lat: $latitude, Lon: $longitude");
      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: userId,
        data: {
          'defaultAddress': address, 
          'latitude': latitude,    
          'longitude': longitude,  
        },
      );
      return getUserById(userId); 
    } catch (e) {
      print(
          "[UserRepository] Error actualizando datos de ubicación para $userId: $e");
      if (e is AppwriteException) {
        print(
            "[UserRepository] AppwriteException (updateUserLocationData): ${e.message} (Code: ${e.code})");
      }
      rethrow;
    }
  }

  Future<List<UserModel>> getUsers() async {
    print(
        "[UserRepository.getUsers] Fetching all users from ${AppwriteConstants.usersCollectionId}");
    final response = await databases.listDocuments(
      databaseId: AppwriteConstants.databaseId,
      collectionId: AppwriteConstants.usersCollectionId,
    );
    return response.documents.map((doc) {
      final data = Map<String, dynamic>.from(doc.data);
      data['\$id'] = doc.$id;
      return UserModel.fromJson(data);
    }).toList();
  }
}