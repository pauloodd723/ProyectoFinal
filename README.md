# Proyecto final - GameShopX

GameShopX es una aplicacion para la venta y intercambios de videojuegos en tiempo real, tanto como compras, descuentos, mensajes y ventas son algunas de sus funciones

## Librerias / Dependencias

dependencies:

  flutter:
    sdk: flutter
    
  flutter_map: ^6.1.0
  
  http: ^1.2.0
  
  latlong2: ^0.9.1
  
  cupertino_icons: ^1.0.8
  
  get: ^4.7.2
  
  appwrite: ^15.0.2
  
  intl: ^0.19.0
  
  image_picker: ^1.1.2
  

dev_dependencies:
  flutter_test:
    sdk: flutter
    
  flutter_lints: ^5.0.0

dependency_overrides:

  flutter_web_auth_2: ^4.0.0

## Credenciales en appwrite

endpoint = 'https://cloud.appwrite.io/v1';

projectId = '67e47f860038ef82c414';

databaseId = '67e48069000c6349986e'; 

usersCollectionId = '67e48093002c64d336c1'; 

gameListingsCollectionId = 'games_collection_id'; 

notificationsCollectionId = '682d16800000235fb2ea'; 

purchaseHistoryCollectionId = '682d18af0018df461550'; 

chatsCollectionId = '68333b840006884d8183';       

messagesCollectionId = '683341df0025f6de7c32';  

gameImagesBucketId = '682a50cd0005f389086b';
