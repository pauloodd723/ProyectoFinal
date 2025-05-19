// lib/presentation/pages/edit_listing_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/model/game_listing_model.dart';

class EditListingPage extends StatefulWidget {
  final GameListingModel listing;

  const EditListingPage({super.key, required this.listing});

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _formKey = GlobalKey<FormState>();
  final GameListingController gameListingController = Get.find();
  final AuthController authController = Get.find();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _conditionController;

  XFile? _pickedImageXFile; // Para la nueva imagen seleccionada
  Uint8List? _newImageBytes; // Bytes de la nueva imagen para preview
  String? _currentFileIdInDocument; // ID del archivo de imagen actual (originalmente widget.listing.imageUrl)
  String? _currentImageUrlPreview; // URL de la imagen actual para preview inicial

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.listing.title);
    _priceController = TextEditingController(text: widget.listing.price.toStringAsFixed(0));
    _descriptionController = TextEditingController(text: widget.listing.description);
    _conditionController = TextEditingController(text: widget.listing.gameCondition);
    
    _currentFileIdInDocument = widget.listing.imageUrl; // Este es el ID del archivo
    _currentImageUrlPreview = widget.listing.getDisplayImageUrl(); // Este construye la URL para mostrar
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedXFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );

    if (pickedXFile != null) {
      _pickedImageXFile = pickedXFile;
      _newImageBytes = await _pickedImageXFile!.readAsBytes();
      setState(() {}); // Actualizar UI para mostrar la nueva imagen
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cambiar Imagen"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String? userId = authController.currentUserId;
    if (userId == null) {
      Get.snackbar("Error", "No se pudo verificar el usuario.", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final Map<String, dynamic> dataFromForm = {
      'title': _titleController.text,
      'price': double.tryParse(_priceController.text) ?? widget.listing.price,
      'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      'gameCondition': _conditionController.text.isNotEmpty ? _conditionController.text : null,
      // 'imageUrl' será manejado por el GameListingController al pasar el nuevo File y el ID antiguo.
    };

    File? fileToUpload; // El File para la nueva imagen, si se seleccionó una
    if (_pickedImageXFile != null) {
      if (kIsWeb) {
        print("ADVERTENCIA (EditListingPage): La subida de archivos desde web con XFile.path como File es problemática.");
        Get.snackbar(
          "Subida Web (Aviso)", 
          "La subida de imágenes desde web puede no funcionar como se espera. Se recomienda usar la app móvil para subir imágenes.", 
          snackPosition: SnackPosition.BOTTOM, 
          duration: const Duration(seconds: 7)
        );
        // Considera no crear el File o manejarlo diferente para web
      }
      try {
        fileToUpload = File(_pickedImageXFile!.path);
      } catch (e) {
        print("Error creando File desde XFile.path en EditListingPage (puede ser normal en web): $e");
        Get.snackbar("Error de Archivo", "No se pudo preparar la imagen para subir.", snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }

    // Se pasa _currentFileIdInDocument, que es el widget.listing.imageUrl (ID del archivo actual)
    await gameListingController.updateListing(
      widget.listing.id,
      dataFromForm, // Datos del formulario (sin el ID de imagen explícito aquí)
      userId,
      fileToUpload, // Nueva imagen (File) si la hay
      _currentFileIdInDocument, // ID del archivo de imagen actual en el documento
    );

    if (gameListingController.error.value.isEmpty) {
      Get.back(); // Volver a la página anterior
      Get.snackbar(
        "Éxito",
        "Artículo actualizado correctamente.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "Error al Actualizar",
        gameListingController.error.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Artículo'),
         actions: [
            IconButton(
                icon: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
                tooltip: 'Eliminar Artículo',
                onPressed: () async {
                     Get.defaultDialog(
                        title: "Confirmar Eliminación",
                        middleText: "¿Estás seguro de que quieres eliminar este artículo: ${widget.listing.title}?",
                        textConfirm: "Eliminar",
                        textCancel: "Cancelar",
                        confirmTextColor: Colors.white,
                        buttonColor: Theme.of(context).colorScheme.error,
                        onConfirm: () async {
                          Get.back(); // Cerrar diálogo
                          // Pasar widget.listing.imageUrl (ID del archivo) al controlador
                          await gameListingController.deleteListing(widget.listing.id, widget.listing.imageUrl);
                           if (gameListingController.error.value.isNotEmpty) {
                                Get.snackbar("Error", "No se pudo eliminar el artículo: ${gameListingController.error.value}",
                                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
                            } else {
                                Get.back(); // Volver a la página anterior (home)
                                Get.snackbar("Éxito", "Artículo eliminado permanentemente.",
                                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                            }
                        }
                      );
                },
            )
        ],
      ),
      body: Obx(() { // Para reaccionar a gameListingController.isLoading
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: _newImageBytes != null // Si hay una nueva imagen seleccionada (en bytes)
                            ? ClipRRect( 
                                borderRadius: BorderRadius.circular(11),
                                child: Image.memory(_newImageBytes!, fit: BoxFit.cover))
                            : (_currentImageUrlPreview != null && _currentImageUrlPreview!.isNotEmpty // Sino, si hay una URL de la imagen actual
                                ? ClipRRect( 
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.network(
                                      _currentImageUrlPreview!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) => Icon(Icons.broken_image, size: 50, color: Colors.grey[700]),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                    ))
                                : Column( // Placeholder si no hay ninguna imagen
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 50, color: Colors.grey[700]),
                                      const SizedBox(height: 8),
                                      Text("Toca para cambiar la imagen", style: TextStyle(color: Colors.grey[700])),
                                    ],
                                  )),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Título del Juego', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingresa un título';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingresa un precio';
                        if (double.tryParse(value) == null) return 'Número inválido';
                        if (double.parse(value) <= 0) return 'El precio debe ser mayor a cero';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _conditionController,
                      decoration: const InputDecoration(labelText: 'Condición (opcional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: gameListingController.isLoading.value ? null : _submitForm,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: gameListingController.isLoading.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Guardar Cambios'),
                    ),
                  ],
                ),
              ),
            ),
            if (gameListingController.isLoading.value)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      }),
    );
  }
}
