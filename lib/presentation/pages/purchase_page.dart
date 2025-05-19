// lib/presentation/pages/purchase_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/model/game_listing_model.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';

class PurchasePage extends StatelessWidget {
  final GameListingModel listing;

  const PurchasePage({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();
    
    // Obtener la URL de la imagen usando el método del modelo.
    final String? imageUrl = listing.getDisplayImageUrl();

    return Scaffold(
      appBar: AppBar(
        title: Text('Comprar: ${listing.title}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print("Error cargando imagen de red en PurchasePage ($imageUrl): $error");
                          return Container(
                              color: Colors.grey[300], // Un color de fondo más claro para el placeholder
                              child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey[600]));
                        },
                      )
                    : Container( 
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey[600])),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              listing.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(listing.price),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            _buildDetailRow(context, Icons.person_outline, 'Vendedor:', listing.sellerName),
            if (listing.gameCondition != null && listing.gameCondition!.isNotEmpty)
              _buildDetailRow(context, Icons.shield_outlined, 'Condición:', listing.gameCondition!),
            if (listing.description != null && listing.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Descripción:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(listing.description!, style: Theme.of(context).textTheme.bodyLarge),
            ],
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            Text(
              'Información del Comprador (Tú):',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(context, Icons.account_circle_outlined, 'Nombre:', authController.currentUserName ?? 'No disponible'),
            _buildDetailRow(context, Icons.email_outlined, 'Email:', authController.currentUserEmail ?? 'No disponible'),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Proceder al Pago (Simulado)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
                onPressed: () {
                  Get.snackbar(
                    'Compra Simulada',
                    '¡Gracias por tu "compra" de ${listing.title}!',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
             Center(
              child: Text(
                "Nota: Esta es una simulación. No se realizará ningún cargo real.",
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Text('$label ', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
