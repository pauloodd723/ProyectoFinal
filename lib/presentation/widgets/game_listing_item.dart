// lib/presentation/widgets/game_listing_item.dart
import 'package:flutter/material.dart';
import 'package:proyecto_final/model/game_listing_model.dart';

class GameListingItem extends StatelessWidget {
  final GameListingModel listing;

  const GameListingItem({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del Juego
            AspectRatio(
              aspectRatio: 16 / 9, // Proporción común para imágenes
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: listing.imageUrl != null && listing.imageUrl!.isNotEmpty
                    ? Image.network(
                        listing.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                              child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ));
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: Colors.grey[800],
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey[600], size: 40),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.videogame_asset_off,
                            color: Colors.grey[600], size: 40),
                        alignment: Alignment.center,
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Título del Juego
            Text(
              listing.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Precio
            Text(
              '\$${listing.price.toStringAsFixed(2)}', // Formato de moneda
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),

            // Vendedor
            Text(
              'Vendido por: ${listing.sellerName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),

            // Podrías añadir más detalles o botones aquí (ej. "Ver Detalles")
          ],
        ),
      ),
    );
  }
}