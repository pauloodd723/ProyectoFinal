// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/date_symbol_data_local.dart'; // Para inicializar formatos de fecha locales

import 'package:proyecto_final/core/config/app_config.dart';
import 'package:proyecto_final/data/repositories/auth_repository.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/user_controller.dart'; // Aunque no se usa directamente, es bueno tenerlo si se expande
import 'package:proyecto_final/data/repositories/user_repository.dart';

import 'package:proyecto_final/data/repositories/game_listing_repository.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/presentation/pages/start_page.dart'; // Página inicial
import 'package:proyecto_final/presentation/pages/home_page.dart'; // Página principal si está logueado
import 'package:proyecto_final/presentation/pages/login_page.dart'; // Página de login si no está logueado

void main() async { // Convertido a async para await
  WidgetsFlutterBinding.ensureInitialized();

  // Para formatos de fecha en español (Colombia en este caso)
  await initializeDateFormatting('es_CO', null);


  // Configuración de Appwrite
  final client = AppwriteConfig.initClient();
  final databases = Databases(client);
  final account = Account(client);
  final storage = Storage(client); // NUEVO: Instancia de Storage

  // Dependencias de Autenticación
  Get.put(AuthRepository(account));
  // Inyectar AuthController y esperar a que cargue el usuario antes de decidir la página inicial
  final AuthController authController = Get.put(AuthController(Get.find()));


  // Dependencias de Usuarios (si se usan extensivamente en el futuro)
  Get.put(UserRepository(databases));
  Get.put(UserController(repository: Get.find()));

  // Dependencias de Listados de Juegos
  // MODIFICADO: Pasar storage al repositorio
  Get.put(GameListingRepository(databases, storage)); 
  Get.put(GameListingController(repository: Get.find()));

  runApp(MyAppLoader(authController: authController)); // Pasa el authController
}


// NUEVO: Widget para manejar la carga inicial y decidir la página
class MyAppLoader extends StatelessWidget {
  final AuthController authController;
  const MyAppLoader({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return Obx(() { // Obx para reaccionar a los cambios de isLoading en AuthController
      Widget homeWidget;
      if (authController.isLoading.value && authController.appwriteUser.value == null) {
        // Muestra un splash screen o loading mientras se verifica el estado de auth
        homeWidget = const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      } else if (authController.isUserLoggedIn) {
        homeWidget = HomePage();
      } else {
        // Si no está logueado (o después del primer chequeo isLoading es false y no hay usuario)
        // Podrías tener una StartPage que luego lleve a Login/Register, o directamente a Login.
        // Por simplicidad, si no hay usuario después de la carga inicial, vamos a StartPage.
        // Si _loadCurrentUserOnStartup ya navegó, esta lógica podría no ser necesaria aquí.
        // Pero es una buena guarda.
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
            primary: Colors.deepPurpleAccent,
            secondary: Colors.tealAccent, // Un color secundario para acentos
            error: Colors.redAccent,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05), // Más sutil para tema oscuro
             border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), // Más redondeado
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder( // Borde cuando no está enfocado
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder( // Borde cuando está enfocado
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
            ),
            labelStyle: TextStyle(color: Colors.grey[400]),
            hintStyle: TextStyle(color: Colors.grey[500]), // Un poco más oscuro para hints
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Un poco más de padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Consistente con inputs
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.tealAccent, // Usar color secundario
               shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            )
          ),
          cardTheme: CardTheme( // Estilo para las tarjetas
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.grey[850], // Un color de fondo para las tarjetas en tema oscuro
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.tealAccent,
            foregroundColor: Colors.black87,
          ),
          dialogTheme: DialogTheme( // Estilo para diálogos
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 16),
          )
        ),
        home: homeWidget,
        // No necesitas definir initialBinding si los pones directamente en main()
        // initialBinding: AppBindings(), // Si prefieres usar Bindings
      );
    });
  }
}

// Opcional: Si quieres usar Bindings para organizar dependencias
// class AppBindings extends Bindings {
//   @override
//   void dependencies() {
//     // Ya están en main, pero si los mueves aquí:
//     // final client = AppwriteConfig.initClient();
//     // final databases = Databases(client);
//     // final account = Account(client);
//     // final storage = Storage(client);

//     // Get.put(AuthRepository(account));
//     // Get.put(AuthController(Get.find()), permanent: true); // permanent si es necesario

//     // Get.put(UserRepository(databases));
//     // Get.put(UserController(repository: Get.find()));

//     // Get.put(GameListingRepository(databases, storage));
//     // Get.put(GameListingController(repository: Get.find()));
//   }
// }
