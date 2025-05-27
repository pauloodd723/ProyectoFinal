import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/user_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/model/user_model.dart';
import 'package:proyecto_final/presentation/widgets/game_listing_item.dart';
import 'package:proyecto_final/controllers/auth_controller.dart'; 
import 'package:proyecto_final/controllers/chat_controller.dart'; 
import 'package:proyecto_final/presentation/pages/chat_message_page.dart'; 
import 'package:proyecto_final/data/repositories/auth_repository.dart'; 

class SellerProfilePage extends StatefulWidget {
  final String sellerId; 
  final String sellerName;

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
  final AuthController _authController = Get.find(); 
  final ChatController _chatController = Get.find(); 

  @override
  void initState() {
    super.initState();
    _userController.clearSelectedUser();
    _userController.fetchUserById(widget.sellerId);
    _gameListingController.fetchListingsForSeller(widget.sellerId);
  }

  void _contactUser(UserModel sellerProfile) async {
    if (!_authController.isUserLoggedIn) {
      Get.snackbar("Acción Requerida", "Debes iniciar sesión para contactar usuarios.", snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_authController.currentUserId == sellerProfile.$id) {
      Get.snackbar("Info", "No puedes enviarte mensajes a ti mismo desde esta página de perfil.", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    final chat = await _chatController.openOrCreateChat(
      otherUserId: sellerProfile.$id,
    );

    if (Get.isDialogOpen ?? false) Get.back(); 

    if (chat != null) {
      String? photoUrl = _userController.selectedUserProfileImageUrl.value;
      if (photoUrl.isEmpty || photoUrl.contains("placehold.co")) {
          photoUrl = null; 
      }


      Get.to(() => ChatMessagePage(
            chatId: chat.id,
            otherUserId: sellerProfile.$id,
            otherUserName: sellerProfile.username,
            otherUserPhotoUrl: photoUrl,
          ));
    } else {
      Get.snackbar("Error", "No se pudo iniciar la conversación. Inténtalo de nuevo más tarde.", snackPosition: SnackPosition.BOTTOM);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
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
          return Center(child: Text('No se pudo cargar el perfil de: ${widget.sellerName}.'));
        }

        final UserModel seller = _userController.selectedUser.value!;
        final String profileImageUrl = _userController.selectedUserProfileImageUrl.value;
        final String userAddress = seller.defaultAddress ?? "Ubicación no especificada";
        final String userCoords = (seller.latitude != null && seller.longitude != null)
            ? "Lat: ${seller.latitude!.toStringAsFixed(4)}, Lon: ${seller.longitude!.toStringAsFixed(4)}"
            : "";


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
              const SizedBox(height: 4),
              Center(
                child: Text(
                  seller.email, 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ),
              if (seller.defaultAddress != null && seller.defaultAddress!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: [
                       Text("Ubicación:", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[400])),
                       Text(userAddress, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center,),
                       if (seller.latitude != null)
                        Text(userCoords, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
                    ],
                  )
                ),
              ],
              const SizedBox(height: 20),
              if (_authController.currentUserId != seller.$id)
                ElevatedButton.icon(
                  icon: const Icon(Icons.message_outlined),
                  label: Text('Contactar a ${seller.username}'),
                  onPressed: () => _contactUser(seller),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              const SizedBox(height: 24),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Artículos de ${seller.username}:',
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
      if (_gameListingController.isLoadingSellerListings.value && _gameListingController.sellerListings.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
      }
      
      final availableListings = _gameListingController.sellerListings.where((l) => l.status == 'available').toList();
      
      if (availableListings.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Este usuario no tiene artículos disponibles en este momento.'),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: availableListings.length,
        itemBuilder: (context, index) {
          final listing = availableListings[index];
          return GameListingItem(listing: listing);
        },
      );
    });
  }
}