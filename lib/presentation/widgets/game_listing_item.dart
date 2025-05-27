import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/controllers/chat_controller.dart';
import 'package:proyecto_final/model/game_listing_model.dart';
import 'package:proyecto_final/presentation/pages/edit_listing_page.dart';
import 'package:proyecto_final/presentation/pages/purchase_page.dart';
import 'package:proyecto_final/presentation/pages/seller_profile_page.dart';
import 'package:proyecto_final/presentation/pages/chat_message_page.dart';
import 'package:proyecto_final/data/repositories/auth_repository.dart';

class GameListingItem extends StatelessWidget {
  final GameListingModel listing;

  const GameListingItem({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();
    final GameListingController gameListingController = Get.find();
    final ChatController chatController = Get.find();
    final bool isOwner = authController.currentUserId == listing.sellerId;
    final String? imageUrl = listing.getDisplayImageUrl();

    print("[GameListingItem] Juego: ${listing.title}, Status: '${listing.status}', Es Dueño: $isOwner, Precio: ${listing.price}");

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40),
                            alignment: Alignment.center,
                          );
                        })
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 40),
                        alignment: Alignment.center,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              listing.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(listing.price),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                if (listing.sellerId.isNotEmpty) {
                  Get.to(() => SellerProfilePage(
                        sellerId: listing.sellerId,
                        sellerName: listing.sellerName,
                      ));
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  'Vendido por: ${listing.sellerName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ),
            ),
            if (listing.gameCondition != null && listing.gameCondition!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Condición: ${listing.gameCondition}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isOwner) ...[
                  TextButton.icon(
                    icon: Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).colorScheme.secondary),
                    label: Text('Editar', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                    onPressed: () {
                      Get.to(() => EditListingPage(listing: listing));
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                    label: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    onPressed: () {
                        Get.defaultDialog(
                          title: "Confirmar Eliminación",
                          middleText: "¿Estás seguro de que quieres eliminar este artículo: ${listing.title}?",
                          textConfirm: "Eliminar",
                          textCancel: "Cancelar",
                          confirmTextColor: Colors.white,
                          buttonColor: Theme.of(context).colorScheme.error,
                          onConfirm: () async {
                            Get.back();
                            await gameListingController.deleteListing(listing.id, listing.imageUrl);
                            if (gameListingController.error.value.isNotEmpty) {
                              Get.snackbar("Error", "No se pudo eliminar el artículo: ${gameListingController.error.value}",
                                  snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
                            } else {
                              Get.snackbar("Éxito", "Artículo eliminado permanentemente.",
                                  snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                            }
                          }
                        );
                    },
                  ),
                ] else ...[ // Si NO es el dueño
                  TextButton.icon(
                    icon: Icon(Icons.message_outlined, size: 18, color: Theme.of(context).colorScheme.secondary),
                    label: Text('Contactar', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                    onPressed: () async {
                      if (!authController.isUserLoggedIn) {
                        Get.snackbar("Acción Requerida", "Debes iniciar sesión para contactar al vendedor.", snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      if (authController.currentUserId == listing.sellerId) {
                        Get.snackbar("Info", "No puedes enviarte mensajes a ti mismo por un anuncio.");
                        return;
                      }
                      Get.dialog(
                        const Center(child: CircularProgressIndicator()),
                        barrierDismissible: false,
                      );
                      final chat = await chatController.openOrCreateChat(
                        otherUserId: listing.sellerId,
                        listingId: listing.id,
                      );
                      if (Get.isDialogOpen ?? false) Get.back();

                      if (chat != null) {
                        String otherUserNameForChat = listing.sellerName;
                        String? otherUserPhotoUrlForChat;
                        int otherParticipantIndex = chat.participants.indexWhere((id) => id == listing.sellerId);

                        if (otherParticipantIndex != -1) {
                            if (chat.participantNames != null && chat.participantNames!.length > otherParticipantIndex) {
                                otherUserNameForChat = chat.participantNames![otherParticipantIndex];
                            }
                            if (chat.participantPhotoIds != null && chat.participantPhotoIds!.length > otherParticipantIndex && chat.participantPhotoIds![otherParticipantIndex].isNotEmpty) {
                                final authRepo = Get.find<AuthRepository>();
                                otherUserPhotoUrlForChat = authRepo.getProfilePictureUrl(chat.participantPhotoIds![otherParticipantIndex]);
                            }
                        }
                        
                        Get.to(() => ChatMessagePage(
                              chatId: chat.id,
                              otherUserId: listing.sellerId,
                              otherUserName: otherUserNameForChat,
                              otherUserPhotoUrl: otherUserPhotoUrlForChat,
                            ));
                      } else {
                        Get.snackbar("Error", "No se pudo iniciar la conversación. Inténtalo de nuevo.");
                      }
                    },
                  ),
                  const Spacer(),
                  if (listing.status == 'available')
                    ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                      label: const Text('Comprar'),
                      onPressed: () { 
                          if (!authController.isUserLoggedIn) {
                            Get.snackbar("Acción Requerida", "Debes iniciar sesión para comprar artículos.", snackPosition: SnackPosition.BOTTOM);
                            return; 
                          }
                          Get.to(() => PurchasePage(listing: listing));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 14),
                      )
                    )
                  else if (listing.status == 'sold')
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text('VENDIDO', style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
                      ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}