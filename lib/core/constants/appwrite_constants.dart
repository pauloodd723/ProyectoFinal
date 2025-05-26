// lib/core/constants/appwrite_constants.dart
class AppwriteConstants {
  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String projectId = '67e47f860038ef82c414'; // Your Project ID
  static const String databaseId = '67e48069000c6349986e'; // Your Database ID

  // Collection IDs
  static const String usersCollectionId = '67e48093002c64d336c1'; // Used for public user profiles potentially
  static const String gameListingsCollectionId = 'games_collection_id'; // Your Game Listings Collection ID

  // NEW Collection IDs - REPLACE WITH YOUR ACTUAL GENERATED IDs
  static const String notificationsCollectionId = '682d16800000235fb2ea'; // REPLACE
  static const String purchaseHistoryCollectionId = '682d18af0018df461550'; // REPLACE

  static const String chatsCollectionId = '68333b840006884d8183';         // <<--- REEMPLAZA ESTO
  static const String messagesCollectionId = '683341df0025f6de7c32';   // <<--- REEMPLAZA ESTO

  // Storage Bucket ID
  static const String gameImagesBucketId = '682a50cd0005f389086b';
}