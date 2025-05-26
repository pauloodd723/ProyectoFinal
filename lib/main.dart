// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/date_symbol_data_local.dart'; // Para formato de fechas

// Configuración y Constantes
import 'package:proyecto_final/core/config/app_config.dart';

// Repositorios
import 'package:proyecto_final/data/repositories/auth_repository.dart';
import 'package:proyecto_final/data/repositories/user_repository.dart';
import 'package:proyecto_final/data/repositories/game_listing_repository.dart';
import 'package:proyecto_final/data/repositories/notification_repository.dart';
import 'package:proyecto_final/data/repositories/purchase_history_repository.dart';
import 'package:proyecto_final/data/repositories/chat_repository.dart'; 
import 'package:proyecto_final/data/repositories/message_repository.dart'; 

// Controladores
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/user_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/controllers/notification_controller.dart';
import 'package:proyecto_final/controllers/chat_controller.dart'; 

// Páginas
import 'package:proyecto_final/presentation/pages/start_page.dart';
import 'package:proyecto_final/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO', null);

  final client = AppwriteConfig.initClient();
  final databases = Databases(client);
  final account = Account(client);
  final storage = Storage(client);
  final realtime = Realtime(client);

  // --- INYECCIÓN DE DEPENDENCIAS CON GetX ---

  // 1. Repositorios
  Get.put(AuthRepository(account, storage));
  Get.put(UserRepository(databases));
  Get.put(GameListingRepository(databases, storage));
  Get.put(NotificationRepository(databases));
  Get.put(PurchaseHistoryRepository(databases));
  Get.put(ChatRepository(databases, Get.find<UserRepository>())); 
  Get.put(MessageRepository(databases, realtime));


  // 2. Controladores 
  Get.put(GameListingController(repository: Get.find<GameListingRepository>()));
  
  // AuthController primero, ya que otros pueden depender de su estado de inicialización
  final AuthController authController = Get.put(AuthController(Get.find<AuthRepository>()));

  // UserController necesita UserRepository
  Get.put(UserController(Get.find<UserRepository>())); // CORREGIDO: Pasar como argumento posicional
  
  Get.put(NotificationController(Get.find<NotificationRepository>()));
  Get.put(ChatController(Get.find<ChatRepository>(), Get.find<MessageRepository>()));

  runApp(MyAppLoader(authController: authController));
}

class MyAppLoader extends StatelessWidget {
  final AuthController authController;

  const MyAppLoader({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    // Usar un FutureBuilder o un Obx para esperar a que AuthController termine su carga inicial
    // Este Obx ya estaba en tu código original y debería funcionar bien.
    return Obx(() {
      Widget homeWidget;
      // Muestra un loader solo si está cargando Y aún no hay usuario (estado inicial absoluto)
      if (authController.isLoading.value && authController.appwriteUser.value == null && authController.localUser.value == null) {
        homeWidget = const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      } else if (authController.isUserLoggedIn) {
        homeWidget = HomePage();
      } else {
        homeWidget = const StartPage();
      }

      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GameShopX',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
            primary: Colors.deepPurpleAccent, // Un morado más vibrante para elementos primarios
            secondary: Colors.tealAccent,    // Un acento contrastante
            error: Colors.redAccent[400],        // Un rojo fuerte para errores
            surface: Colors.grey[850],       // Superficies de tarjetas, diálogos
            onSurface: Colors.white,
            background: Colors.grey[900],      // Fondo general de Scaffolds
            onBackground: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.grey[900], // Fondo oscuro general
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
            ),
            labelStyle: TextStyle(color: Colors.grey[400]),
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIconColor: Colors.grey[400],
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
            foregroundColor: Colors.tealAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          )),
          cardTheme: CardTheme(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.grey[850], // Un poco más claro que el fondo
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0) // Margen por defecto para tarjetas
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.tealAccent,
            foregroundColor: Colors.black87,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[900], // Consistente con el fondo del scaffold
            elevation: 0, // Sin sombra para un look más plano si se desea
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          dialogTheme: DialogTheme(
            backgroundColor: Colors.grey[850],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            titleTextStyle: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            contentTextStyle:
                const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          dividerTheme: DividerThemeData(
            color: Colors.grey[700],
            thickness: 0.5,
          ),
           bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.grey[900],
            selectedItemColor: Colors.deepPurpleAccent,
            unselectedItemColor: Colors.grey[500],
          ),
          tabBarTheme: TabBarTheme(
            labelColor: Colors.deepPurpleAccent,
            unselectedLabelColor: Colors.grey[500],
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2.0),
            )
          )
        ),
        home: homeWidget,
      );
    });
  }
}