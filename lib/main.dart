// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';

import 'package:proyecto_final/core/config/app_config.dart';
import 'package:proyecto_final/data/repositories/auth_repository.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/user_controller.dart';
import 'package:proyecto_final/data/repositories/user_repository.dart';
import 'package:proyecto_final/presentation/pages/splash_page.dart';

// NUEVOS IMPORTS
import 'package:proyecto_final/data/repositories/game_listing_repository.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final client = AppwriteConfig.initClient();
  final databases = Databases(client);
  final account = Account(client);

  // Dependencies data base (users)
  Get.put(UserRepository(databases)); // Asegúrate que 'databases' es el mismo objeto Databases(client)
  Get.put(UserController(repository: Get.find()));

  // Dependencies account (auth)
  Get.put(AuthRepository(account));
  Get.put(AuthController(Get.find()));

  // NUEVO: Dependencies para GameListings
  Get.put(GameListingRepository(databases)); // Usa el mismo objeto 'databases'
  Get.put(GameListingController(repository: Get.find()));


  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GameShopX', // Cambiado el título
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // Un color temático
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true, // Si quieres usar Material 3
        brightness: Brightness.dark, // Tema oscuro como base
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme( // Estilo para la barra de búsqueda
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: SplashPage(),
    );
  }
}