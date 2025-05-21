// lib/controllers/user_controller.dart
import 'package:get/get.dart';
import 'package:proyecto_final/model/user_model.dart';
import 'package:proyecto_final/data/repositories/user_repository.dart';
import 'package:proyecto_final/data/repositories/auth_repository.dart';
// NUEVOS IMPORTS
import 'package:proyecto_final/model/purchase_history_model.dart';
import 'package:proyecto_final/data/repositories/purchase_history_repository.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';


class UserController extends GetxController {
  final UserRepository repository;
  late final AuthRepository _authRepository;
  // NUEVO: Repositorio de historial de compras
  late final PurchaseHistoryRepository _purchaseHistoryRepository;
  // AuthController para obtener el ID del usuario actual
  late final AuthController _authController;


  UserController({required this.repository});

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = false.obs; // Para la lista general de usuarios
  final RxString error = ''.obs; // Error general

  // Para la página de perfil de un vendedor específico
  final Rx<UserModel?> selectedUser = Rx<UserModel?>(null);
  final RxBool isLoadingSelectedUser = false.obs;
  final RxString selectedUserProfileImageUrl = ''.obs;
  final RxString selectedUserError = ''.obs;

  // NUEVO: Observables para Reportes
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
    // NUEVO: Obtener instancias
    _purchaseHistoryRepository = Get.find<PurchaseHistoryRepository>();
    _authController = Get.find<AuthController>();

    // Podríamos cargar los reportes si el usuario está logueado,
    // pero es mejor hacerlo bajo demanda cuando el usuario navegue a la página de reportes.
    // ever(_authController.appwriteUser, _handleUserChangeForReports);
    // if (_authController.isUserLoggedIn) {
    //   loadUserActivity();
    // }
  }

  // void _handleUserChangeForReports(appwrite_models.User? user) {
  //   if (user != null) {
  //     loadUserActivity();
  //   } else {
  //     clearUserActivity();
  //   }
  // }

  // void clearUserActivity() {
  //   purchasedGames.clear();
  //   soldGames.clear();
  //   purchasedGamesError.value = '';
  //   soldGamesError.value = '';
  // }

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


  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      error.value = '';
      final fetchedUsers = await repository.getUsers();
      users.assignAll(fetchedUsers);
    } catch (e) {
      print("[UserController.fetchUsers] Error: $e");
      error.value = "Error al cargar la lista de usuarios.";
      users.clear();
    } finally {
      isLoading.value = false;
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
          String initials = fetchedUser.username.isNotEmpty ? fetchedUser.username[0].toUpperCase() : "S";
          selectedUserProfileImageUrl.value = "https://placehold.co/150x150/7F00FF/FFFFFF?text=$initials";
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

  // --- NUEVOS MÉTODOS PARA REPORTES ---
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
      // Usaremos el historial de compras para obtener las ventas, ya que es más directo al evento de venta.
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