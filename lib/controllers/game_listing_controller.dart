import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/data/repositories/game_listing_repository.dart';
import 'package:proyecto_final/model/game_listing_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:proyecto_final/core/constants/appwrite_constants.dart'; 

class GameListingController extends GetxController {
  final GameListingRepository repository;

  GameListingController({required this.repository});

  final RxList<GameListingModel> listings = <GameListingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;
  final Rx<PriceSortOption> currentSortOption = PriceSortOption.none.obs;

  // For Seller Profile Page
  final RxList<GameListingModel> sellerListings = <GameListingModel>[].obs;
  final RxBool isLoadingSellerListings = false.obs;


  @override
  void onInit() {
    super.onInit();
    fetchListings();
    debounce(searchQuery, (_) => fetchListings(search: searchQuery.value, sortOption: currentSortOption.value),
        time: const Duration(milliseconds: 500));
    ever(currentSortOption, (_) => fetchListings(search: searchQuery.value, sortOption: currentSortOption.value));
  }

  Future<void> fetchListings({String? search, PriceSortOption? sortOption, bool forceRefresh = false}) async {
    if (!forceRefresh && listings.isNotEmpty && search == searchQuery.value && sortOption == currentSortOption.value && !isLoading.value) {

    }

    try {
      isLoading.value = true;
      error.value = '';
      final PriceSortOption effectiveSortOption = sortOption ?? currentSortOption.value;
      final fetchedListings = await repository.getGameListings(
          searchQuery: search, sortOption: effectiveSortOption);
      listings.assignAll(fetchedListings);
    } catch (e) {
      print("[GameListingController] Error al cargar listados: $e");
      error.value = "Error al cargar listados: ${e.toString()}";
      listings.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchListingsForSeller(String sellerId) async {
    try {
      isLoadingSellerListings.value = true;
      error.value = ''; 
      final fetched = await repository.getGameListings(sellerId: sellerId, sortOption: PriceSortOption.none); 
      sellerListings.assignAll(fetched);
    } catch (e) {
      print("[GameListingController] Error al cargar listados del vendedor $sellerId: $e");
      sellerListings.clear();
    } finally {
      isLoadingSellerListings.value = false;
    }
  }


  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void updateSortOption(PriceSortOption option) {
    currentSortOption.value = option;
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
        print("[GameListingController.addListing] No se proporcionó imageFile.");
      }
      
      final GameListingModel listingToAdd = newListingData.copyWith(status: 'available');


      await repository.addGameListing(
        listingToAdd,
        currentUserId,
        uploadedFileId: uploadedFileId,
      );
      fetchListings(forceRefresh: true);
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
      String? currentFileIdInDocument) async {
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
      dataToUpdateInDb['imageUrl'] = finalFileIdForDocument;
      if (!dataToUpdateInDb.containsKey('status')) {
        final existingListing = listings.firstWhereOrNull((l) => l.id == documentId);
        if (existingListing != null) {
          dataToUpdateInDb['status'] = existingListing.status;
        } else {

        }
      }


      await repository.updateGameListing(
          documentId,
          dataToUpdateInDb,
          currentUserId,
          newUploadedFileId: (newImageToUpload != null) ? finalFileIdForDocument : null,
          oldFileId: (newImageToUpload != null && currentFileIdInDocument != null && currentFileIdInDocument != finalFileIdForDocument)
              ? currentFileIdInDocument
              : null);
      fetchListings(forceRefresh: true);
    } catch (e) {
      print("[GameListingController] Error al actualizar el listado: $e");
      error.value = "Error al actualizar el listado: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteListing(String documentId, String? fileIdInDocument) async {
    try {
      isLoading.value = true;
      error.value = '';
      await repository.deleteGameListing(documentId, fileIdInDocument);
      fetchListings(forceRefresh: true);
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

  String getFilePreviewUrl(String fileIdToPreview) {
    if (fileIdToPreview.isEmpty) return '';
    return repository.getFilePreviewUrl(fileIdToPreview);
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

  Future<bool> updateSellerNameForUserListings(String sellerId, String newSellerName) async {
    print("[GameListingController.updateSellerNameForUserListings] Updating listings for seller $sellerId to name $newSellerName");
    bool allSuccess = true;
    try {
      
      isLoading.value = true; 

      final sellerDocs = await repository.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.gameListingsCollectionId,
        queries: [Query.equal('sellerId', sellerId)]
      );

      if (sellerDocs.documents.isEmpty) {
        print("[GameListingController.updateSellerNameForUserListings] No listings found for seller $sellerId.");
        isLoading.value = false;
        return true; 
      }
      
      print("[GameListingController.updateSellerNameForUserListings] Found ${sellerDocs.documents.length} listings for seller $sellerId.");

      for (var doc in sellerDocs.documents) {
        try {
          await repository.updateListingSellerName(doc.$id, newSellerName);
        } catch (e) {
          print("[GameListingController.updateSellerNameForUserListings] Failed to update listing ${doc.$id}: $e");
          allSuccess = false; 
        }
      }
      await fetchListings(forceRefresh: true);
      if (sellerListings.isNotEmpty && sellerListings.first.sellerId == sellerId) {
          await fetchListingsForSeller(sellerId);
      }

    } catch (e) {
      print("[GameListingController.updateSellerNameForUserListings] General error: $e");
      allSuccess = false;
    } finally {
      isLoading.value = false;
    }
    return allSuccess;
  }

  Future<bool> updateListingStatus(String listingId, String newStatus, String currentUserId) async {
    try {
      isLoading.value = true; 
      await repository.updateGameListing(
        listingId,
        {'status': newStatus},
        currentUserId,
      );
      await fetchListings(forceRefresh: true);
      final listingIndexInSellerListings = sellerListings.indexWhere((l) => l.id == listingId);
      if (listingIndexInSellerListings != -1) {
          await fetchListingsForSeller(sellerListings[listingIndexInSellerListings].sellerId);
      }
      return true;
    } catch (e) {
      print("[GameListingController] Error updating listing $listingId status to $newStatus: $e");
      Get.snackbar("Error", "No se pudo actualizar el estado del artículo.", snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}