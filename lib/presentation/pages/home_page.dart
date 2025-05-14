// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/presentation/widgets/game_listing_item.dart';
import 'package:proyecto_final/presentation/pages/add_listing_page.dart'; // Asegúrate que esta sea la página con el formulario
import 'package:proyecto_final/presentation/pages/profile_page.dart'; // Página de perfil

// --- Definiciones de Placeholder Pages (si aún no tienes las reales) ---
// Si ya tienes ProfilePage y AddListingPage reales y bien definidas, puedes borrar estas.
// Pero asegúrate que los archivos existan y las clases estén definidas.

// class ProfilePage extends StatelessWidget {
//   const ProfilePage({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(appBar: AppBar(title: const Text('Mi Perfil')), body: const Center(child: Text('Página de Perfil Placeholder')));
//   }
// }

// class AddListingPage extends StatelessWidget {
//   const AddListingPage({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(appBar: AppBar(title: const Text('Añadir Artículo')), body: const Center(child: Text('Página Añadir Artículo Placeholder')));
//   }
// }
// --- Fin Placeholder Pages ---


class HomePage extends StatelessWidget {
  HomePage({super.key});

  // Controladores de GetX
  final GameListingController gameListingController = Get.find();
  final AuthController authController = Get.find(); // AuthController se obtiene aquí

  // Controlador para el campo de texto de búsqueda
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GameShopX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              print("--- HomePage: Botón Perfil presionado ---"); // DEBUG
              print("HomePage: Valor de authController.appwriteUser.value para perfil: ${authController.appwriteUser.value}"); // DEBUG
              if (authController.appwriteUser.value != null) {
                print("HomePage: Usuario logueado para perfil. Navegando a ProfilePage..."); // DEBUG
                Get.to(() => const ProfilePage()); // Asegúrate que ProfilePage esté definida
              } else {
                print("HomePage: Usuario NO logueado para perfil. Mostrando Snackbar."); // DEBUG
                Get.snackbar("Acción Requerida", "Debes iniciar sesión para ver tu perfil.",
                snackPosition: SnackPosition.BOTTOM);
              }
            },
          ),
          IconButton( // Botón de Logout
            icon: const Icon(Icons.logout),
            onPressed: () async {
              print("--- HomePage: Botón Logout presionado ---"); // DEBUG
              await authController.logout();
              // AuthController ya maneja la navegación a LoginPage después del logout
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar juegos por título...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => gameListingController.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        gameListingController.updateSearchQuery('');
                      },
                    )
                  : const SizedBox.shrink() // No muestra nada si no hay texto de búsqueda
                ),
              ),
              onChanged: (value) {
                // Actualiza la query en el controlador de listados de juegos
                gameListingController.updateSearchQuery(value);
              },
            ),
          ),

          // Listado de Juegos
          Expanded(
            child: Obx(() { // Obx reacciona a los cambios en las variables observables del controller
              if (gameListingController.isLoading.value && gameListingController.listings.isEmpty) {
                // Muestra indicador de carga si está cargando y no hay listados previos
                return const Center(child: CircularProgressIndicator());
              }
              if (gameListingController.error.value.isNotEmpty && gameListingController.listings.isEmpty) {
                // Muestra mensaje de error si hay un error y no hay listados
                return Center(child: Text('Error: ${gameListingController.error.value}'));
              }
              if (gameListingController.listings.isEmpty) {
                // Muestra mensaje si no hay juegos disponibles
                return const Center(child: Text('No hay juegos disponibles en este momento.'));
              }
              // Construye la lista de juegos
              return ListView.builder(
                itemCount: gameListingController.listings.length,
                itemBuilder: (context, index) {
                  final listing = gameListingController.listings[index];
                  return GameListingItem(listing: listing); // Widget para cada item del listado
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("--- HomePage: Botón (+) presionado ---"); // DEBUG
          // authController ya está disponible como miembro de la clase
          print("HomePage: Valor de authController.appwriteUser.value: ${authController.appwriteUser.value}"); // DEBUG
          if (authController.appwriteUser.value != null) { // Verifica si el usuario está cargado (logueado)
            print("HomePage: Usuario SÍ está logueado según appwriteUser. Navegando a AddListingPage..."); // DEBUG
            Get.to(() => const AddListingPage()); // Navega a la página real con el formulario
          } else {
            print("HomePage: Usuario NO está logueado según appwriteUser o es null. Mostrando Snackbar."); // DEBUG
            Get.snackbar("Acción Requerida", "Debes iniciar sesión para añadir artículos.",
            snackPosition: SnackPosition.BOTTOM);
            // Opcionalmente, puedes llevarlo a la página de login:
            // Get.to(() => LoginPage());
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Añadir Artículo',
      ),
    );
  }
}
