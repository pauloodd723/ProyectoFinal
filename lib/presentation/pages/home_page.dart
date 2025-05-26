// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart' as material; // Usar prefijo para claridad
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/data/repositories/game_listing_repository.dart'; // Importar para PriceSortOption
import 'package:proyecto_final/presentation/widgets/game_listing_item.dart';
import 'package:proyecto_final/presentation/pages/add_listing_page.dart';
import 'package:proyecto_final/presentation/pages/profile_page.dart';
import 'package:proyecto_final/presentation/pages/login_page.dart';
// NUEVOS IMPORTS
import 'package:proyecto_final/controllers/notification_controller.dart';
import 'package:proyecto_final/presentation/pages/notifications_page.dart';
import 'package:proyecto_final/presentation/pages/chat_list_page.dart'; // IMPORTADO PARA EL BOTÓN DE MENSAJES


class HomePage extends material.StatelessWidget {
  HomePage({super.key});

  final GameListingController gameListingController = Get.find();
  final AuthController authController = Get.find();
  final NotificationController notificationController = Get.find(); // Obtener NotificationController
  final material.TextEditingController _searchController = material.TextEditingController();

  @override
  material.Widget build(material.BuildContext context) {
    // NotificationController ya tiene lógica en onInit para cargar si el usuario está logueado.
    // No es estrictamente necesario llamarlo aquí de nuevo a menos que haya un caso específico.

    return material.Scaffold(
      appBar: material.AppBar(
        title: const material.Text('GameShopX'),
        actions: [
          material.PopupMenuButton<PriceSortOption>(
            icon: const material.Icon(material.Icons.sort),
            tooltip: "Ordenar por precio",
            onSelected: (PriceSortOption result) {
              gameListingController.updateSortOption(result);
            },
            itemBuilder: (material.BuildContext context) => <material.PopupMenuEntry<PriceSortOption>>[
              const material.PopupMenuItem<PriceSortOption>(
                value: PriceSortOption.none,
                child: material.Text('Más Recientes'),
              ),
              const material.PopupMenuItem<PriceSortOption>(
                value: PriceSortOption.lowestFirst,
                child: material.Text('Precio: Menor a Mayor'),
              ),
              const material.PopupMenuItem<PriceSortOption>(
                value: PriceSortOption.highestFirst,
                child: material.Text('Precio: Mayor a Menor'),
              ),
            ],
          ),
          // NUEVO BOTÓN DE MENSAJES
          material.IconButton(
            icon: const material.Icon(material.Icons.chat_bubble_outline_rounded), // Icono para mensajes
            tooltip: 'Mis Mensajes',
            onPressed: () {
              if (authController.isUserLoggedIn) {
                Get.to(() => const ChatListPage());
              } else {
                Get.snackbar("Acción Requerida", "Debes iniciar sesión para ver tus mensajes.",
                    snackPosition: SnackPosition.BOTTOM);
                Get.to(() => LoginPage());
              }
            },
          ),
          Obx(() {
            final unreadCount = notificationController.unreadCount.value;
            return material.IconButton(
              icon: material.Badge(
                label: material.Text(unreadCount > 9 ? '9+' : unreadCount.toString()),
                isLabelVisible: unreadCount > 0,
                child: const material.Icon(material.Icons.notifications_outlined),
              ),
              tooltip: 'Notificaciones',
              onPressed: () {
                Get.to(() => const NotificationsPage());
              },
            );
          }),
          material.IconButton(
            icon: const material.Icon(material.Icons.person_outline),
            tooltip: 'Mi Perfil',
            onPressed: () {
              if (authController.isUserLoggedIn) {
                Get.to(() => const ProfilePage());
              } else {
                Get.snackbar("Acción Requerida", "Debes iniciar sesión para ver tu perfil.",
                    snackPosition: SnackPosition.BOTTOM);
                Get.to(() => LoginPage());
              }
            },
          ),
          material.IconButton(
            icon: const material.Icon(material.Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await authController.logout();
            },
          ),
        ],
      ),
      body: material.Column(
        children: [
          material.Padding(
            padding: const material.EdgeInsets.all(16.0),
            child: material.TextField(
              controller: _searchController,
              decoration: material.InputDecoration(
                hintText: 'Buscar juegos por título...',
                prefixIcon: const material.Icon(material.Icons.search),
                suffixIcon: Obx(() => gameListingController.searchQuery.value.isNotEmpty
                    ? material.IconButton(
                        icon: const material.Icon(material.Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          gameListingController.updateSearchQuery('');
                        },
                      )
                    : const material.SizedBox.shrink()),
              ),
              onChanged: (value) {
                gameListingController.updateSearchQuery(value);
              },
            ),
          ),
          material.Expanded(
            child: Obx(() { 
              if (gameListingController.isLoading.value && gameListingController.listings.isEmpty) {
                return const material.Center(child: material.CircularProgressIndicator());
              }
              if (gameListingController.error.value.isNotEmpty && gameListingController.listings.isEmpty) {
                return material.Center(
                  child: material.Padding(
                    padding: const material.EdgeInsets.all(16.0),
                    child: material.Column(
                      mainAxisAlignment: material.MainAxisAlignment.center,
                      children: [
                        material.Text('Error: ${gameListingController.error.value}', textAlign: material.TextAlign.center),
                        const material.SizedBox(height: 10),
                        material.ElevatedButton(
                            onPressed: () => gameListingController.fetchListings(forceRefresh: true), // Añadir forceRefresh
                            child: const material.Text("Reintentar"))
                      ],
                    ),
                  )
                );
              }
              if (gameListingController.listings.isEmpty) {
                return material.Center(
                  child: material.Padding(
                    padding: const material.EdgeInsets.all(16.0),
                      child: material.Text(
                        gameListingController.searchQuery.value.isEmpty && gameListingController.currentSortOption.value == PriceSortOption.none
                            ? 'No hay juegos disponibles. ¡Publica el tuyo!'
                            : 'No se encontraron juegos con los filtros actuales.',
                        textAlign: material.TextAlign.center,
                        style: material.Theme.of(context).textTheme.titleMedium,
                      ),
                  )
                );
              }
              return material.RefreshIndicator(
                onRefresh: () => gameListingController.fetchListings(
                  search: gameListingController.searchQuery.value,
                  sortOption: gameListingController.currentSortOption.value,
                  forceRefresh: true // Añadir forceRefresh
                ),
                child: material.ListView.builder(
                  itemCount: gameListingController.listings.length,
                  itemBuilder: (material.BuildContext context, int index) {
                    final listing = gameListingController.listings[index];
                    return GameListingItem(listing: listing);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: material.FloatingActionButton.extended(
        onPressed: () {
          if (authController.isUserLoggedIn) {
            Get.to(() => const AddListingPage());
          } else {
            Get.snackbar("Acción Requerida", "Debes iniciar sesión para añadir artículos.",
                snackPosition: SnackPosition.BOTTOM);
              Get.to(() => LoginPage());
          }
        },
        icon: const material.Icon(material.Icons.add),
        label: const material.Text('Vender'),
        tooltip: 'Añadir Artículo',
      ),
    );
  }
}