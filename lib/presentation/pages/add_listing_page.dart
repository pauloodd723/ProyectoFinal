// lib/presentation/pages/add_listing_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/model/game_listing_model.dart';

class AddListingPage extends StatefulWidget {
  // Es importante que esta página sea const si la llamas con const AddListingPage()
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  final GameListingController gameListingController = Get.find();
  final AuthController authController = Get.find();

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController(); // Temporal para URL de imagen
  final _conditionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final String? userId = authController.currentUserId;
      final String? userName = authController.currentUserName; // Asegúrate que esto devuelve el nombre del usuario logueado

      if (userId == null || userName == null) {
        Get.snackbar(
          "Error de Autenticación",
          "No se pudo obtener la información del usuario. Por favor, inicia sesión de nuevo.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final newListing = GameListingModel(
        id: '', // Appwrite generará el ID del documento
        title: _titleController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        imageUrl: _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
        gameCondition: _conditionController.text.isNotEmpty ? _conditionController.text : null,
        sellerId: userId, // Se pasa al método del controller
        sellerName: userName, // Se pasa al método del controller
        status: 'disponible', // Valor por defecto
        // createdAt no se establece aquí, Appwrite lo maneja
      );

      // Llamamos al método del GameListingController
      await gameListingController.addListing(newListing, userId, userName);

      if (gameListingController.error.value.isEmpty) {
        Get.back(); // Volver a la página anterior (HomePage) si todo fue bien
        Get.snackbar(
          "Éxito",
          "Artículo añadido correctamente.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // Si hubo un error, el GameListingController ya debería tenerlo en error.value
        // y podrías tener un Obx escuchándolo en esta página o simplemente mostrar un snackbar
        Get.snackbar(
          "Error al Publicar",
          gameListingController.error.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos GetBuilder o Obx para el estado de carga del GameListingController
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Nuevo Artículo'),
      ),
      body: Obx(() { // Obx para reaccionar a isLoading del GameListingController
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView( // Usamos ListView para evitar overflow si el teclado aparece
                  children: <Widget>[
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Título del Juego'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa un título';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa un precio';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor, ingresa un número válido para el precio';
                        }
                        if (double.parse(value) <= 0) {
                          return 'El precio debe ser mayor que cero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                      maxLines: 3,
                      // No es obligatorio, así que no necesita validador a menos que quieras una longitud mínima/máxima
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _conditionController,
                      decoration: const InputDecoration(labelText: 'Condición (ej: Nuevo, Usado - Buen estado) (opcional)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'URL de la Imagen (opcional, temporal)'),
                      keyboardType: TextInputType.url,
                       validator: (value) { // Validación opcional para URL
                        if (value != null && value.isNotEmpty) {
                          bool isValidUrl = Uri.tryParse(value)?.hasAbsolutePath ?? false;
                          if (!isValidUrl) {
                            return 'Por favor, ingresa una URL válida o déjalo vacío.';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      // Deshabilitar el botón si está cargando
                      onPressed: gameListingController.isLoading.value ? null : _submitForm,
                      child: gameListingController.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Publicar Artículo'),
                    ),
                  ],
                ),
              ),
            ),
            // Overlay de carga global para la página
            if (gameListingController.isLoading.value)
              Container(
                color: Colors.black.withOpacity(0.3), // Semi-transparente
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      }),
    );
  }
}