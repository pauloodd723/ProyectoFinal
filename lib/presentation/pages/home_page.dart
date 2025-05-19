// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/presentation/widgets/game_listing_item.dart';
import 'package:proyecto_final/presentation/pages/add_listing_page.dart';
import 'package:proyecto_final/presentation/pages/profile_page.dart';
import 'package:proyecto_final/presentation/pages/login_page.dart'; // Para redirigir si no está logueado

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final GameListingController gameListingController = Get.find();
  final AuthController authController = Get.find();
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en el usuario para recargar listados si es necesario (ej. al hacer login/logout desde otra parte)
    // Esto es opcional, ya que fetchListings se llama en onInit.
    // ever(authController.appwriteUser, (_) => gameListingController.fetchListings());


    return Scaffold(
      appBar: AppBar(
        title: const Text('GameShopX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi Perfil',
            onPressed: () {
              if (authController.isUserLoggedIn) {
                Get.to(() => const ProfilePage());
              } else {
                Get.snackbar("Acción Requerida", "Debes iniciar sesión para ver tu perfil.",
                  snackPosition: SnackPosition.BOTTOM);
                Get.to(() => LoginPage()); // Opcional: llevar a login
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await authController.logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
                    : const SizedBox.shrink()),
              ),
              onChanged: (value) {
                gameListingController.updateSearchQuery(value);
              },
            ),
          ),
          Expanded(
            child: Obx(() {
              if (gameListingController.isLoading.value && gameListingController.listings.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (gameListingController.error.value.isNotEmpty && gameListingController.listings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${gameListingController.error.value}', textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        ElevatedButton(onPressed: () => gameListingController.fetchListings(), child: const Text("Reintentar"))
                      ],
                    ),
                  )
                );
              }
              if (gameListingController.listings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                     child: Text(
                        gameListingController.searchQuery.value.isEmpty
                            ? 'No hay juegos disponibles en este momento. ¡Sé el primero en publicar!'
                            : 'No se encontraron juegos para "${gameListingController.searchQuery.value}".',
                        textAlign: TextAlign.center,
                      ),
                  )
                );
              }
              return RefreshIndicator(
                onRefresh: () => gameListingController.fetchListings(search: gameListingController.searchQuery.value),
                child: ListView.builder(
                  itemCount: gameListingController.listings.length,
                  itemBuilder: (context, index) {
                    final listing = gameListingController.listings[index];
                    return GameListingItem(listing: listing);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (authController.isUserLoggedIn) {
            Get.to(() => const AddListingPage());
          } else {
            Get.snackbar("Acción Requerida", "Debes iniciar sesión para añadir artículos.",
              snackPosition: SnackPosition.BOTTOM);
             Get.to(() => LoginPage()); // Opcional: llevar a login
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Vender'),
        tooltip: 'Añadir Artículo',
      ),
    );
  }
}
