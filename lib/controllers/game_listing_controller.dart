// lib/controllers/game_listing_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/data/repositories/game_listing_repository.dart';
import 'package:proyecto_final/model/game_listing_model.dart';
import 'package:image_picker/image_picker.dart';

class GameListingController extends GetxController {
  final GameListingRepository repository;

  GameListingController({required this.repository});

  final RxList<GameListingModel> listings = <GameListingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchListings();
    debounce(searchQuery, (_) => fetchListings(search: searchQuery.value),
        time: const Duration(milliseconds: 500));
  }

  Future<void> fetchListings({String? search}) async {
    try {
      isLoading.value = true;
      error.value = '';
      final fetchedListings = await repository.getGameListings(searchQuery: search);
      listings.assignAll(fetchedListings);
    } catch (e) {
      print("[GameListingController] Error al cargar listados: $e");
      error.value = "Error al cargar listados: ${e.toString()}";
      listings.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  Future<void> addListing(GameListingModel newListingData, File? imageFile, String currentUserId) async {
    try {
      isLoading.value = true;
      error.value = '';
      String? uploadedFileId;

      if (imageFile != null) {
        uploadedFileId = await repository.uploadGameImage(imageFile, currentUserId);
        if (uploadedFileId == null) {
          error.value = "Error al subir la imagen del juego. No se pudo crear el artículo.";
          Get.snackbar("Error de Imagen", error.value, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
          isLoading.value = false;
          return;
        }
      } else {
        // Si la imagen es obligatoria (atributo 'imageUrl' requerido en Appwrite),
        // la UI debería haberlo validado. Si llega aquí sin imagen y es requerida,
        // Appwrite devolverá un error que se capturará en el catch.
        print("[GameListingController.addListing] No se proporcionó imageFile.");
      }

      // El 'uploadedFileId' (que es el ID del archivo de Storage) se pasa al repositorio.
      // El repositorio lo usará para el campo 'imageUrl' del modelo al crear el documento.
      await repository.addGameListing(
        newListingData,
        currentUserId,
        uploadedFileId: uploadedFileId,
      );
      
      fetchListings();
    } catch (e) {
      print("[GameListingController] Error al añadir el listado: $e");
      error.value = "Error al añadir el listado: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateListing(
    String documentId,
    Map<String, dynamic> dataFromForm,
    String currentUserId,
    File? newImageToUpload,
    String? currentFileIdInDocument // Este es el valor de listing.imageUrl (ID del archivo actual)
  ) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      String? finalFileIdForDocument = currentFileIdInDocument;

      if (newImageToUpload != null) {
        final String? uploadedNewFileId = await repository.uploadGameImage(newImageToUpload, currentUserId);
        if (uploadedNewFileId == null) {
          error.value = "Error al subir la nueva imagen del juego. No se pudo actualizar el artículo.";
          Get.snackbar("Error de Imagen", error.value, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red);
          isLoading.value = false;
          return;
        }
        finalFileIdForDocument = uploadedNewFileId;
      }
      
      Map<String, dynamic> dataToUpdateInDb = {...dataFromForm};
      // Asegúrate de que el campo que se envía a la BD se llame 'imageUrl'
      dataToUpdateInDb['imageUrl'] = finalFileIdForDocument;

      await repository.updateGameListing(
        documentId,
        dataToUpdateInDb,
        currentUserId,
        newUploadedFileId: (newImageToUpload != null) ? finalFileIdForDocument : null, 
        oldFileId: (newImageToUpload != null && currentFileIdInDocument != null && currentFileIdInDocument != finalFileIdForDocument) ? currentFileIdInDocument : null
      );
      
      fetchListings();
    } catch (e) {
      print("[GameListingController] Error al actualizar el listado: $e");
      error.value = "Error al actualizar el listado: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  // CORREGIDO: El segundo parámetro es el ID del archivo de imagen almacenado en el documento (listing.imageUrl)
  Future<void> deleteListing(String documentId, String? fileIdInDocument) async {
    try {
      isLoading.value = true;
      error.value = '';
      // El repositorio espera el ID del archivo para borrarlo de Storage
      await repository.deleteGameListing(documentId, fileIdInDocument);
      fetchListings();
    } catch (e) {
      print("[GameListingController] Error al eliminar el listado: $e");
      error.value = "Error al eliminar el listado: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  Future<File?> pickImage(ImageSource source) async {
     try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print("Error al seleccionar imagen: $e");
      Get.snackbar("Error de Imagen", "No se pudo seleccionar la imagen: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
    return null;
  }

  // El nombre del método en el modelo es getImageUrlPreview()
  String getFilePreviewUrl(String fileIdToPreview, {int? width, int? height, int? quality = 75}) {
    if (fileIdToPreview.isEmpty) return '';
    return repository.getFilePreviewUrl(fileIdToPreview, width: width, height: height, quality: quality);
  }

  String formatDate(String dateString) {
    if (dateString.isEmpty) {
      return 'No disponible';
    }
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy, hh:mm a', 'es_CO').format(dateTime.toLocal());
    } catch (e) {
      print("[GameListingController] Error formateando fecha '$dateString': $e");
      return dateString;
    }
  }
}
