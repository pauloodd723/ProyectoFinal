// lib/controllers/user_controller.dart
import 'package:flutter/foundation.dart'; // para kIsWeb
import 'package:flutter/material.dart';  // Para Colors y otros widgets de UI si los usaras directamente
import 'package:get/get.dart';
import 'package:proyecto_final/data/repositories/user_repository.dart';
import 'package:proyecto_final/model/user_model.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/data/repositories/auth_repository.dart'; // Para _authRepository
import 'package:proyecto_final/data/repositories/purchase_history_repository.dart';
import 'package:proyecto_final/model/purchase_history_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// TU CLAVE DE API DE OPENROUTESERVICE (Asegúrate que sea la correcta)
const String OPENROUTESERVICE_API_KEY = "5b3ce3597851110001cf6248c481db0e564d40e7bee3c06a5c924711";

class UserController extends GetxController {
  final UserRepository repository;
  late final AuthRepository _authRepository; // Para obtener URL de imagen de perfil en fetchUserById
  late final PurchaseHistoryRepository _purchaseHistoryRepository;
  late final AuthController _authController;

  UserController(this.repository);

  final RxBool isLoading = false.obs; // Para la lista general de usuarios (si se usa)
  final RxString error = ''.obs; // Error general

  // Para la página de perfil de un vendedor específico
  final Rx<UserModel?> selectedUser = Rx<UserModel?>(null);
  final RxBool isLoadingSelectedUser = false.obs;
  final RxString selectedUserProfileImageUrl = ''.obs;
  final RxString selectedUserError = ''.obs;

  // Para el proceso de actualizar la dirección del usuario actual
  final RxBool isLoadingUpdate = false.obs;


  final RxList<PurchaseHistoryModel> purchasedGames = <PurchaseHistoryModel>[].obs;
  final RxBool isLoadingPurchasedGames = false.obs;
  final RxString purchasedGamesError = ''.obs;

  final RxList<PurchaseHistoryModel> soldGames = <PurchaseHistoryModel>[].obs;
  final RxBool isLoadingSoldGames = false.obs;
  final RxString soldGamesError = ''.obs;


  @override
  void onInit() {
    super.onInit();
    _authRepository = Get.find<AuthRepository>();
    _purchaseHistoryRepository = Get.find<PurchaseHistoryRepository>();
    _authController = Get.find<AuthController>();
  }

  Future<void> updateUserDefaultLocation(String address) async {
    if (!_authController.isUserLoggedIn || _authController.currentUserId == null) {
      Get.snackbar(
        "Error de Autenticación", 
        "Debes estar autenticado para actualizar tu ubicación.",
        backgroundColor: Colors.red,
        colorText: Colors.white
      );
      return;
    }
    isLoadingUpdate.value = true;
    try {
      String? addressToSave = address.trim().isEmpty ? null : address.trim();
      double? lat;
      double? lon;

      if (addressToSave != null && addressToSave.isNotEmpty) {
        if (OPENROUTESERVICE_API_KEY == "TU_OPENROUTESERVICE_API_KEY_AQUI" || OPENROUTESERVICE_API_KEY.isEmpty || OPENROUTESERVICE_API_KEY == "5b3ce3597851110001cf6248c481db0e564d40e7bee3c06a5c924711" && OPENROUTESERVICE_API_KEY.length < 40 ) { // Placeholder check
            Get.snackbar(
                "Configuración Requerida", 
                "La API Key de OpenRouteService no parece estar configurada correctamente.", 
                duration: const Duration(seconds: 5), 
                backgroundColor: Colors.orange, 
                colorText: Colors.black
            );
            // No intentar geocodificar si la clave es el placeholder o vacía
        } else {
            try {
              final Uri geocodeUri = Uri.parse(
                  'https://api.openrouteservice.org/geocode/search?api_key=$OPENROUTESERVICE_API_KEY&text=${Uri.encodeComponent(addressToSave)}');
              
              print("[UserController] Geocodificando con OpenRouteService: $geocodeUri");
              final response = await http.get(geocodeUri);

              if (response.statusCode == 200) {
                final decodedResponse = json.decode(response.body);
                if (decodedResponse['features'] != null && (decodedResponse['features'] as List).isNotEmpty) {
                  final coordinates = decodedResponse['features'][0]['geometry']['coordinates'];
                  lon = (coordinates[0] as num).toDouble(); // Longitude is first
                  lat = (coordinates[1] as num).toDouble(); // Latitude is second
                  print("[UserController] Dirección geocodificada: '$addressToSave' -> Lat: $lat, Lon: $lon");
                } else {
                  print("[UserController] No se encontraron coordenadas para: '$addressToSave' usando OpenRouteService. Respuesta: ${response.body}");
                  Get.snackbar("Advertencia de Ubicación", "No se pudieron encontrar coordenadas para la dirección. Se guardará solo el texto.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.amber, colorText: Colors.black);
                }
              } else {
                print("[UserController] Error de API OpenRouteService (Geocoding): ${response.statusCode} - ${response.body}");
                Get.snackbar("Error de Servicio de Ubicación", "Error del servicio de geocodificación (${response.statusCode}). Se guardará solo el texto.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
              }
            } catch (e) {
              print("[UserController] Error durante Geocodificación (OpenRouteService) para '$addressToSave': $e");
              Get.snackbar("Error de Ubicación", "No se pudo convertir la dirección a coordenadas. Intenta ser más específico o revisa tu conexión. Se guardará solo el texto.", snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 5), backgroundColor: Colors.red, colorText: Colors.white);
            }
        }
      }

      // Llama al método en UserRepository que espera lat y lon
      UserModel? updatedUser = await repository.updateUserLocationData(
        userId: _authController.currentUserId!,
        address: addressToSave, // La dirección de texto
        latitude: lat,          // La latitud obtenida (puede ser null)
        longitude: lon,         // La longitud obtenida (puede ser null)
      );
      
      if (updatedUser != null) {
        _authController.updateLocalUser(updatedUser); // Actualizar el UserModel en AuthController
        Get.snackbar("Éxito", "Ubicación predeterminada actualizada.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Error de Actualización", "No se pudo actualizar la ubicación en la base de datos.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error General", "Ocurrió un error general al actualizar la ubicación: ${e.toString()}", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoadingUpdate.value = false;
    }
  }

  Future<void> fetchUserById(String userId) async {
    try {
      isLoadingSelectedUser.value = true;
      selectedUser.value = null;
      selectedUserProfileImageUrl.value = '';
      selectedUserError.value = '';

      final fetchedUser = await repository.getUserById(userId);
      if (fetchedUser != null) {
        selectedUser.value = fetchedUser;
        if (fetchedUser.profileImageId != null && fetchedUser.profileImageId!.isNotEmpty) {
          selectedUserProfileImageUrl.value = _authRepository.getProfilePictureUrl(fetchedUser.profileImageId!);
        } else {
          String initials = fetchedUser.username.isNotEmpty ? fetchedUser.username[0].toUpperCase() : "S"; // Fallback a 'S' de Seller
          selectedUserProfileImageUrl.value = "https://placehold.co/150x150/7F00FF/FFFFFF?text=$initials&font=roboto";
        }
      } else {
        selectedUserError.value = "Vendedor no encontrado.";
      }
    } catch (e) {
      print("[UserController.fetchUserById] Error cargando perfil del vendedor $userId: $e");
      selectedUserError.value = "Error al cargar el perfil del vendedor.";
      selectedUser.value = null;
      selectedUserProfileImageUrl.value = '';
    } finally {
      isLoadingSelectedUser.value = false;
    }
  }

  void clearSelectedUser() {
    selectedUser.value = null;
    selectedUserProfileImageUrl.value = '';
    selectedUserError.value = '';
  }
  
  Future<void> loadUserActivity() async {
    if (!_authController.isUserLoggedIn || _authController.currentUserId == null) {
      purchasedGamesError.value = "Usuario no autenticado.";
      soldGamesError.value = "Usuario no autenticado.";
      return;
    }
    final String currentUserId = _authController.currentUserId!;
    await fetchPurchasedGames(currentUserId);
    await fetchSoldGames(currentUserId);
  }

  Future<void> fetchPurchasedGames(String buyerId, {bool showLoading = true}) async {
    if (showLoading) isLoadingPurchasedGames.value = true;
    purchasedGamesError.value = '';
    try {
      final fetched = await _purchaseHistoryRepository.getPurchasesByBuyer(buyerId);
      purchasedGames.assignAll(fetched);
      print("[UserController] Juegos comprados cargados: ${purchasedGames.length}");
    } catch (e) {
      print("[UserController] Error al cargar juegos comprados: $e");
      purchasedGamesError.value = "No se pudieron cargar tus compras.";
      purchasedGames.clear();
    } finally {
      if (showLoading) isLoadingPurchasedGames.value = false;
    }
  }

  Future<void> fetchSoldGames(String sellerId, {bool showLoading = true}) async {
    if (showLoading) isLoadingSoldGames.value = true;
    soldGamesError.value = '';
    try {
      final fetched = await _purchaseHistoryRepository.getSalesBySeller(sellerId);
      soldGames.assignAll(fetched);
      print("[UserController] Juegos vendidos cargados: ${soldGames.length}");
    } catch (e) {
      print("[UserController] Error al cargar juegos vendidos: $e");
      soldGamesError.value = "No se pudieron cargar tus ventas.";
      soldGames.clear();
    } finally {
      if (showLoading) isLoadingSoldGames.value = false;
    }
  }
}