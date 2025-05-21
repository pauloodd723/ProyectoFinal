// lib/presentation/pages/seller_profile_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/user_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart'; // Para mostrar otros juegos del vendedor
import 'package:proyecto_final/model/user_model.dart';
import 'package:proyecto_final/presentation/widgets/game_listing_item.dart'; // Para reusar el widget

class SellerProfilePage extends StatefulWidget {
  final String sellerId;
  final String sellerName; // Nombre para mostrar mientras carga el perfil completo

  const SellerProfilePage({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final UserController _userController = Get.find();
  final GameListingController _gameListingController = Get.find();

  @override
  void initState() {
    super.initState();
    // Limpiar datos anteriores y cargar el nuevo perfil
    _userController.clearSelectedUser();
    _userController.fetchUserById(widget.sellerId);
    // Cargar los listados de este vendedor (solo los disponibles)
    _gameListingController.fetchListingsForSeller(widget.sellerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          // Usar el nombre pasado como fallback mientras carga
          return Text(_userController.selectedUser.value?.username ?? widget.sellerName);
        }),
      ),
      body: Obx(() {
        if (_userController.isLoadingSelectedUser.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_userController.selectedUserError.value.isNotEmpty) {
          return Center(child: Text('Error: ${_userController.selectedUserError.value}'));
        }
        if (_userController.selectedUser.value == null) {
          return Center(child: Text('No se pudo cargar el perfil del vendedor: ${widget.sellerName}.'));
        }

        final UserModel seller = _userController.selectedUser.value!;
        final String profileImageUrl = _userController.selectedUserProfileImageUrl.value;

        return RefreshIndicator(
          onRefresh: () async {
            await _userController.fetchUserById(widget.sellerId);
            await _gameListingController.fetchListingsForSeller(widget.sellerId);
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  backgroundImage: (profileImageUrl.isNotEmpty && !profileImageUrl.contains("placehold.co"))
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: (profileImageUrl.isEmpty || profileImageUrl.contains("placehold.co"))
                      ? Text(
                          seller.username.isNotEmpty ? seller.username[0].toUpperCase() : 'S',
                          style: TextStyle(fontSize: 50, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  seller.username,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              // Podrías añadir más información del perfil aquí si la tuvieras,
              // como la fecha de registro, etc., si está en tu UserModel y la cargas.
              // Text("Email: ${seller.email}"), // ¡Cuidado con la privacidad!
              const SizedBox(height: 24),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Otros artículos de ${seller.username}:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _buildSellerListings(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSellerListings() {
    return Obx(() {
      if (_gameListingController.isLoadingSellerListings.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_gameListingController.sellerListings.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Este vendedor no tiene otros artículos disponibles.'),
          ),
        );
      }
      // Mostramos solo los que están 'available'
      final availableListings = _gameListingController.sellerListings.where((l) => l.status == 'available').toList();
       if (availableListings.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Este vendedor no tiene otros artículos disponibles en este momento.'),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true, // Importante dentro de otro ListView
        physics: const NeverScrollableScrollPhysics(), // Para que el scroll lo maneje el ListView padre
        itemCount: availableListings.length,
        itemBuilder: (context, index) {
          final listing = availableListings[index];
          return GameListingItem(listing: listing); // Reutilizamos el widget
        },
      );
    });
  }
}