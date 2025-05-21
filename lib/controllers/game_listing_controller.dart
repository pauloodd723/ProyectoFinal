// lib/controllers/game_listing_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/data/repositories/game_listing_repository.dart';
import 'package:proyecto_final/model/game_listing_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:proyecto_final/core/constants/appwrite_constants.dart'; // For Query

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
    // If not forcing refresh and listings are already populated for the same search/sort, might skip.
    // However, for simplicity, we'll always fetch for now unless it's just a sort/search update.
    if (!forceRefresh && listings.isNotEmpty && search == searchQuery.value && sortOption == currentSortOption.value && !isLoading.value) {
       // If only sortOption or search triggered this, and we already have data, this logic might be too simple.
       // The debounce and ever listeners should handle re-fetching appropriately.
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

  // NEW: Fetch listings for a specific seller
  Future<void> fetchListingsForSeller(String sellerId) async {
    try {
      isLoadingSellerListings.value = true;
      error.value = ''; // Clear general error or use a specific one for seller listings
      final fetched = await repository.getGameListings(sellerId: sellerId, sortOption: PriceSortOption.none); // Default sort for seller page or add specific sort
      sellerListings.assignAll(fetched);
    } catch (e) {
      print("[GameListingController] Error al cargar listados del vendedor $sellerId: $e");
      // Optionally set a specific error for seller listings
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
      
      // Ensure status is 'available' when adding
      final GameListingModel listingToAdd = newListingData.copyWith(status: 'available');


      await repository.addGameListing(
        listingToAdd, // Use the model with status set
        currentUserId,
        uploadedFileId: uploadedFileId,
      );
      fetchListings(forceRefresh: true); // Force refresh to see the new item
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
      // Ensure status is not accidentally overwritten if not in form
      if (!dataToUpdateInDb.containsKey('status')) {
        final existingListing = listings.firstWhereOrNull((l) => l.id == documentId);
        if (existingListing != null) {
          dataToUpdateInDb['status'] = existingListing.status;
        } else {
            // If not found in current listings (e.g. editing from a different context),
            // fetch it or assume 'available' if status is crucial here.
            // For now, we assume the form won't mess with status unless intended.
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

  // NEW: Method called by AuthController to update sellerName in listings
  Future<bool> updateSellerNameForUserListings(String sellerId, String newSellerName) async {
    print("[GameListingController.updateSellerNameForUserListings] Updating listings for seller $sellerId to name $newSellerName");
    bool allSuccess = true;
    try {
      // Fetch all listings by this seller (including sold ones, if necessary, though not typical to update sold records)
      // For simplicity, let's fetch all and update. A more optimized way would be Query.equal('sellerId', sellerId)
      // and then iterate. GameListingRepository needs a method for this.
      // Let's assume we get a list of their listings (or their IDs)
      // This is a simplified example; direct fetching of user's listings is better.
      
      isLoading.value = true; // Show loading as this can take time

      // Fetch listings specifically for this seller ID without status filter initially
      final sellerDocs = await repository.databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.gameListingsCollectionId,
        queries: [Query.equal('sellerId', sellerId)]
      );

      if (sellerDocs.documents.isEmpty) {
        print("[GameListingController.updateSellerNameForUserListings] No listings found for seller $sellerId.");
        isLoading.value = false;
        return true; // No listings to update, so technically success.
      }
      
      print("[GameListingController.updateSellerNameForUserListings] Found ${sellerDocs.documents.length} listings for seller $sellerId.");

      for (var doc in sellerDocs.documents) {
        try {
          await repository.updateListingSellerName(doc.$id, newSellerName);
        } catch (e) {
          print("[GameListingController.updateSellerNameForUserListings] Failed to update listing ${doc.$id}: $e");
          allSuccess = false; // Mark that at least one update failed
        }
      }
      // Refresh the main listings view if any changes occurred
      await fetchListings(forceRefresh: true);
      // Also refresh sellerListings if they are currently populated for this user
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

  // NEW: Method to update a listing's status (e.g., to 'sold')
  Future<bool> updateListingStatus(String listingId, String newStatus, String currentUserId) async {
    try {
      isLoading.value = true; // Or a more specific loader if needed
      await repository.updateGameListing(
        listingId,
        {'status': newStatus},
        currentUserId, // The user performing action (buyer, or system) - for permissions
      );
      await fetchListings(forceRefresh: true); // Refresh main listings
      // If the listing was part of sellerListings, refresh that too
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