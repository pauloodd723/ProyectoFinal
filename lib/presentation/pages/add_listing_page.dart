// lib/presentation/pages/add_listing_page.dart
import 'dart:io';
import 'dart:typed_data'; // Para Uint8List
import 'package:flutter/foundation.dart' show kIsWeb; // Para verificar si es web
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

  XFile? _pickedImageXFile; // Almacena el XFile de image_picker
  Uint8List? _imageBytes; // Almacena los bytes de la imagen para preview con Image.memory

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    // Usar ImagePicker directamente para obtener XFile
    final XFile? pickedXFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70, // Comprimir un poco la imagen
        maxWidth: 1024, // Redimensionar si es muy grande
      );

    if (pickedXFile != null) {
      _pickedImageXFile = pickedXFile;
      _imageBytes = await _pickedImageXFile!.readAsBytes(); // Leer bytes para Image.memory
      setState(() {}); // Actualizar UI para mostrar la imagen
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
      return; // No continuar si el formulario no es válido
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

    // El campo 'imageUrl' en GameListingModel se deja null aquí.
    // El GameListingController y GameListingRepository asignarán el ID del archivo
    // subido al campo 'imageUrl' antes de guardarlo en la base de datos.
    final newListingData = GameListingModel(
      id: '', // Appwrite generará el ID
      title: _titleController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      gameCondition: _conditionController.text.isNotEmpty ? _conditionController.text : null,
      sellerId: userId,
      sellerName: userName,
      status: 'disponible',
      // imageUrl (el ID del archivo) será establecido por el controlador/repositorio
    );

    File? fileToUpload;
    // Para la subida, necesitamos un objeto File si no es web.
    // Si es web, el controlador/repositorio necesitaría manejar XFile/bytes.
    if (_pickedImageXFile != null) {
        if (kIsWeb) {
          // ADVERTENCIA: La subida directa de XFile.path como File no es fiable en web.
          // Se necesitaría que GameListingController y GameListingRepository
          // manejen XFile.readAsBytes() y usen InputFile.fromBytes().
          // Por ahora, se mostrará una advertencia y se intentará la subida
          // que podría fallar o no ser óptima en web.
          print("ADVERTENCIA (AddListingPage): La subida de archivos desde web con XFile.path como File es problemática. Considerar refactorizar a InputFile.fromBytes().");
          Get.snackbar(
            "Subida Web (Aviso)", 
            "La subida de imágenes desde web puede no funcionar como se espera. Se recomienda usar la app móvil para subir imágenes.", 
            snackPosition: SnackPosition.BOTTOM, 
            duration: const Duration(seconds: 7)
          );
          // Para un manejo más robusto, podrías pasar _imageBytes y _pickedImageXFile.name al controller.
          // Por ahora, intentamos crear el File, sabiendo que puede no ser ideal para web.
        }
        try {
          // Esto funciona bien en móvil. En web, XFile.path puede ser una URL de blob.
          fileToUpload = File(_pickedImageXFile!.path);
        } catch (e) {
          print("Error creando File desde XFile.path en AddListingPage (puede ser normal en web): $e");
           Get.snackbar("Error de Archivo", "No se pudo preparar la imagen para subir.", snackPosition: SnackPosition.BOTTOM);
          return; // No continuar si no se puede preparar el archivo
        }
    }

    // Si fileToUpload es null (porque es web y no se pudo crear el File de forma fiable,
    // o porque _pickedImageXFile fue null, aunque ya lo validamos),
    // la lógica en el controller/repo debería manejarlo (ej. no intentar subir).
    // Sin embargo, ya validamos que _pickedImageXFile no sea null.
    // El principal problema aquí es la creación de `File` en web.

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
                          color: Colors.grey[300], // Color de fondo del contenedor de imagen
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: _imageBytes != null
                            ? ClipRRect( // Muestra la imagen seleccionada usando Image.memory
                                borderRadius: BorderRadius.circular(11), // Un poco menos que el contenedor para ver el borde
                                child: Image.memory(_imageBytes!, fit: BoxFit.cover)
                              )
                            : Column( // Placeholder si no hay imagen seleccionada
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
