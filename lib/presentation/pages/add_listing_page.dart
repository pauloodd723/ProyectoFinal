import 'dart:io';
import 'dart:typed_data'; 
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/model/game_listing_model.dart';

class AddListingPage extends StatefulWidget {
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
  final _conditionController = TextEditingController();

  XFile? _pickedImageXFile; 
  Uint8List? _imageBytes; 

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
      _imageBytes = await _pickedImageXFile!.readAsBytes(); 
      setState(() {}); 
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Seleccionar Fuente de Imagen"),
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
    final String? userName = authController.currentUserName;

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
    
    if (_pickedImageXFile == null) {
         Get.snackbar(
          "Imagen Requerida",
          "Por favor, selecciona una imagen para el juego.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
    }

    final newListingData = GameListingModel(
      id: '', 
      title: _titleController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      gameCondition: _conditionController.text.isNotEmpty ? _conditionController.text : null,
      sellerId: userId,
      sellerName: userName,
      status: 'disponible',
    );

    File? fileToUpload;
    if (_pickedImageXFile != null) {
        if (kIsWeb) {
          print("ADVERTENCIA (AddListingPage): La subida de archivos desde web con XFile.path como File es problemática. Considerar refactorizar a InputFile.fromBytes().");
          Get.snackbar(
            "Subida Web (Aviso)", 
            "La subida de imágenes desde web puede no funcionar como se espera. Se recomienda usar la app móvil para subir imágenes.", 
            snackPosition: SnackPosition.BOTTOM, 
            duration: const Duration(seconds: 7)
          );
        }
        try {
          fileToUpload = File(_pickedImageXFile!.path);
        } catch (e) {
          print("Error creando File desde XFile.path en AddListingPage (puede ser normal en web): $e");
           Get.snackbar("Error de Archivo", "No se pudo preparar la imagen para subir.", snackPosition: SnackPosition.BOTTOM);
          return; 
        }
    }

    await gameListingController.addListing(newListingData, fileToUpload, userId);
    if (gameListingController.error.value.isEmpty) {
      Get.back(); 
      Get.snackbar(
        "Éxito",
        "Artículo añadido correctamente.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "Error al Publicar",
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
        title: const Text('Añadir Nuevo Artículo'),
      ),
      body: Obx(() { 
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
                        child: _imageBytes != null
                            ? ClipRRect( 
                                borderRadius: BorderRadius.circular(11), 
                                child: Image.memory(_imageBytes!, fit: BoxFit.cover)
                              )
                            : Column( 
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 50, color: Colors.grey[700]),
                                  const SizedBox(height: 8),
                                  Text("Toca para añadir una imagen", style: TextStyle(color: Colors.grey[700])),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Título del Juego', border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa un precio';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor, ingresa un número válido';
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
                      decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _conditionController,
                      decoration: const InputDecoration(labelText: 'Condición (ej: Nuevo, Usado) (opcional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: gameListingController.isLoading.value ? null : _submitForm,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: gameListingController.isLoading.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Publicar Artículo'),
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
