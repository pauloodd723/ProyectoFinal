import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final AuthController authController = Get.find();

  late TextEditingController _nameController;

  XFile? _pickedImageXFile; 
  Uint8List? _newImageBytesPreview; 
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: authController.currentUserName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final File? imageFileFromPicker = await authController.pickProfileImage(source); 
    if (imageFileFromPicker != null) {
      _pickedImageXFile = XFile(imageFileFromPicker.path); 
      _newImageBytesPreview = await imageFileFromPicker.readAsBytes(); 
      setState(() {});
    }
  }

   Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cambiar Foto de Perfil"),
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() { _isSaving = true; });

    bool nameUpdateAttempted = _nameController.text != (authController.currentUserName ?? '');
    bool pictureUpdateAttempted = _pickedImageXFile != null;
    
    bool nameUpdateSuccess = !nameUpdateAttempted; 
    bool pictureUpdateSuccess = !pictureUpdateAttempted; 

    String? finalErrorMessage;

    if (nameUpdateAttempted) {
      nameUpdateSuccess = await authController.updateProfileName(_nameController.text, showLoadingIndicator: false);
      if (!nameUpdateSuccess) {
        finalErrorMessage = authController.error.value.isNotEmpty ? authController.error.value : "No se pudo actualizar el nombre.";
      }
    }

    if (pictureUpdateAttempted && nameUpdateSuccess) { 
      File? fileToUpload;
      if (kIsWeb) {
        print("ADVERTENCIA (EditProfilePage): La subida de fotos de perfil desde web con XFile.path como File es problemática.");

      } else { 
        try {
          fileToUpload = File(_pickedImageXFile!.path);
        } catch (e) {
          print("Error creando File desde XFile.path en EditProfilePage: $e");
          finalErrorMessage = (finalErrorMessage ?? "") + "\nNo se pudo preparar la foto de perfil.";
          pictureUpdateSuccess = false;
        }
      }

      if (fileToUpload != null) {
        pictureUpdateSuccess = await authController.updateProfilePicture(fileToUpload, showLoadingIndicator: false);
        if (!pictureUpdateSuccess) {
          finalErrorMessage = (finalErrorMessage ?? "") + "\n" + (authController.error.value.isNotEmpty ? authController.error.value : "No se pudo actualizar la foto.");
        }
      } else if (kIsWeb && _pickedImageXFile != null) {

          finalErrorMessage = (finalErrorMessage ?? "") + "\nSubida de foto desde web no implementada completamente.";
          pictureUpdateSuccess = false;
      }
    }
    
    setState(() { _isSaving = false; });

    if (nameUpdateSuccess && pictureUpdateSuccess) {
      if (nameUpdateAttempted || pictureUpdateAttempted) {
         Get.snackbar("Éxito", "Perfil actualizado correctamente.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
         Get.snackbar("Información", "No se realizaron cambios.", snackPosition: SnackPosition.BOTTOM);
      }
      if (mounted) Get.back(); 
    } else {
      if (finalErrorMessage != null && finalErrorMessage.trim().isNotEmpty) {
        Get.snackbar("Error", finalErrorMessage.trim(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white, duration: const Duration(seconds: 4));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    Center(
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Obx(() =>
                              CircleAvatar(
                                radius: 70,
                                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                backgroundImage: _newImageBytesPreview != null
                                    ? MemoryImage(_newImageBytesPreview!)
                                    : (authController.profileImageUrl.value.isNotEmpty && !authController.profileImageUrl.value.contains("placehold.co"))
                                        ? NetworkImage(authController.profileImageUrl.value)
                                        : null,
                                child: (_newImageBytesPreview == null && (authController.profileImageUrl.value.isEmpty || authController.profileImageUrl.value.contains("placehold.co")))
                                    ? Icon(Icons.person, size: 70, color: Theme.of(context).colorScheme.onSurfaceVariant)
                                    : null,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSecondary, size: 20),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _isSaving ? null : _updateProfile,
                    ),
                  ],
                ),
              ),
            ),
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        )
    );
  }
}
