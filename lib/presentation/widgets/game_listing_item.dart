// lib/presentation/widgets/game_listing_item.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/model/game_listing_model.dart';
import 'package:proyecto_final/presentation/pages/edit_listing_page.dart';
import 'package:proyecto_final/presentation/pages/purchase_page.dart';
// Asegúrate que esta importación sea correcta para tu estructura de archivos
import 'package:proyecto_final/presentation/pages/seller_profile_page.dart';


class GameListingItem extends StatelessWidget {
  final GameListingModel listing;

  const GameListingItem({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();
    final GameListingController gameListingController = Get.find();
    final bool isOwner = authController.currentUserId == listing.sellerId;

    final String? imageUrl = listing.getDisplayImageUrl();

    // DEBUG PRINT PARA PROBLEMA 1 (BOTÓN COMPRAR) - (Puedes quitarlo si ya solucionaste eso)
    // print('DEBUG GameListingItem: ID=${listing.id}, Title=${listing.title}, Status=${listing.status}');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
                          print("Error cargando imagen de red ($imageUrl): $error");
                          return Container(
                            color: Colors.grey[800],
                            child: Icon(Icons.broken_image, color: Colors.grey[600], size: 40),
                            alignment: Alignment.center,
                          );
                        })
                    : Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.image_not_supported, color: Colors.grey[600], size: 40),
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
                // --- ESTA ES LA LÍNEA DE PRINT AÑADIDA PARA EL PASO 1 DEL DIAGNÓSTICO DEL PROBLEMA 2 ---
                print("[GameListingItem onTap Seller] Intentando ver perfil del vendedor con ID: '${listing.sellerId}', Nombre: '${listing.sellerName}'");
                // --- FIN DE LA LÍNEA DE PRINT ---

                if (listing.sellerId.isNotEmpty) {
                  Get.to(() => SellerProfilePage(
                        sellerId: listing.sellerId,
                        sellerName: listing.sellerName,
                      ));
                } else {
                  Get.snackbar("Información", "ID del vendedor no disponible.");
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Vendido por: ${listing.sellerName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary, 
                        decoration: TextDecoration.underline, 
                        decorationColor: Theme.of(context).colorScheme.secondary,
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
            const SizedBox(height: 10),

            if (!isOwner && listing.status == 'sold')
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'VENDIDO',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

            if (isOwner)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.secondary),
                    label: Text('Editar', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                    onPressed: () {
                      Get.to(() => EditListingPage(listing: listing));
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: Icon(Icons.delete, size: 18, color: Theme.of(context).colorScheme.error),
                    label: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    onPressed: () async {
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
                              Get.snackbar("Éxito", "Artículo eliminado.",
                                  snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                            }
                          });
                    },
                  ),
                ],
              )
            else if (listing.status == 'available') 
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Comprar'),
                  onPressed: () {
                    if (!authController.isUserLoggedIn) {
                      Get.snackbar(
                          "Acción Requerida", "Debes iniciar sesión para comprar artículos.",
                          snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    Get.to(() => PurchasePage(listing: listing));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  )
                ),
              ),
          ],
        ),
      ),
    );
  }
}