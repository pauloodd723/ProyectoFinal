// lib/controllers/auth_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_auth_models; // Alias específico para Appwrite Auth User
import 'package:proyecto_final/data/repositories/auth_repository.dart';
import 'package:proyecto_final/presentation/pages/home_page.dart';
import 'package:proyecto_final/presentation/pages/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/data/repositories/user_repository.dart';
import 'package:proyecto_final/model/user_model.dart'; // Importa tu UserModel

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<appwrite_auth_models.User?> appwriteUser = Rx(null); // Usuario de Appwrite Auth

  final RxString profileImageUrl = ''.obs; // URL de la foto de perfil actual
  final Rx<UserModel?> localUser = Rx<UserModel?>(null); // Modelo de tu colección 'users'

  final String _profileImageIdKey = 'profileImageId'; // Key para prefs

  late final GameListingController _gameListingController;
  late final UserRepository _userRepository;

  AuthController(this._authRepository);

  @override
  void onInit() {
    super.onInit();
    _gameListingController = Get.find<GameListingController>();
    _userRepository = Get.find<UserRepository>();
    _loadCurrentUserOnStartup();
  }

  Future<void> _fetchLocalUserData(String userId) async {
    print("[AuthController] Intentando cargar datos locales para el usuario: $userId");
    try {
      // No uses isLoading general aquí para no bloquear toda la UI al inicio si falla
      localUser.value = await _userRepository.getUserById(userId);
      if (localUser.value != null) {
        print("[AuthController] Datos locales del usuario cargados: ${localUser.value!.username}, Dirección: ${localUser.value!.defaultAddress}");
      } else {
        print("[AuthController] No se encontró UserModel local para el usuario $userId. Esto es normal si es un nuevo registro y el perfil público aún no se ha creado completamente o si se borró.");
        // Podrías intentar crear un perfil público básico aquí si no existe y el appwriteUser sí.
        // Por ejemplo, si appwriteUser.value != null y localUser.value == null
        // await _userRepository.createOrUpdatePublicUserProfile(
        //   userId: appwriteUser.value!.$id,
        //   name: appwriteUser.value!.name,
        //   email: appwriteUser.value!.email,
        //   // profileImageId y defaultAddress serían null inicialmente
        // );
        // localUser.value = await _userRepository.getUserById(userId); // Reintentar carga
      }
    } catch (e) {
      print("[AuthController] Error cargando datos locales del UserModel para $userId: $e");
      localUser.value = null;
    }
  }

  void updateLocalUser(UserModel updatedUser) {
    // Asegúrate que el ID del appwriteUser (Auth) coincide con el $id del UserModel (DB)
    if (appwriteUser.value != null && appwriteUser.value!.$id == updatedUser.$id) {
      localUser.value = updatedUser;
      print("[AuthController] UserModel local actualizado. Nueva dirección: ${localUser.value?.defaultAddress}");
      // Si la foto de perfil también se actualizó a través de UserModel, refrescar profileImageUrl
      if (updatedUser.profileImageId != null && updatedUser.profileImageId!.isNotEmpty) {
          profileImageUrl.value = _authRepository.getProfilePictureUrl(updatedUser.profileImageId!);
      } else if (updatedUser.profileImageId == null || updatedUser.profileImageId!.isEmpty) {
          profileImageUrl.value = ''; // O tu placeholder
      }
    } else {
       print("[AuthController] No se pudo actualizar localUser: IDs no coinciden o appwriteUser es null.");
    }
  }

  Future<void> _loadCurrentUserOnStartup({bool showGlobalLoading = true}) async {
    if (showGlobalLoading) isLoading.value = true;
    error.value = '';
    localUser.value = null; // Limpiar datos locales al inicio
    profileImageUrl.value = '';

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        appwrite_auth_models.User? fetchedUser = await _authRepository.account.get();
        if (fetchedUser != null) {
          appwriteUser.value = fetchedUser;
          _loadProfilePictureFromPrefs(fetchedUser.prefs.data); // Cargar foto de prefs
          await _fetchLocalUserData(fetchedUser.$id); // Cargar datos de la colección 'users'

          if (fetchedUser.prefs.data == null || !fetchedUser.prefs.data.containsKey('coupons')) {
            await _initializeCouponsForUser();
          }
        } else {
          appwriteUser.value = null;
        }
      } else {
        appwriteUser.value = null;
      }
    } catch (e) {
      print("[AUTH_CTRL._loadCurrentUserOnStartup] Error cargando usuario: $e");
      appwriteUser.value = null;
    } finally {
      if (showGlobalLoading) isLoading.value = false;
    }
  }

  void _loadProfilePictureFromPrefs(Map<String, dynamic>? prefsData) {
    profileImageUrl.value = ''; // Resetea primero
    if (prefsData != null && prefsData.containsKey(_profileImageIdKey)) {
      final String? fileId = prefsData[_profileImageIdKey];
      if (fileId != null && fileId.isNotEmpty) {
        profileImageUrl.value = _authRepository.getProfilePictureUrl(fileId);
      }
    }
  }
  
  Future<void> reloadUser() async {
    print("[AUTH_CTRL.reloadUser] Recargando datos del usuario...");
    await _loadCurrentUserOnStartup(showGlobalLoading: false); // Esto recargará appwriteUser y localUser
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    error.value = '';
    try {
      await _authRepository.login(email: email, password: password);
      appwrite_auth_models.User? fetchedUser = await _authRepository.account.get();
      if (fetchedUser != null) {
        appwriteUser.value = fetchedUser;
        _loadProfilePictureFromPrefs(fetchedUser.prefs.data);
        await _fetchLocalUserData(fetchedUser.$id); // Cargar datos de la colección 'users'

        if (fetchedUser.prefs.data == null || !fetchedUser.prefs.data.containsKey('coupons')) {
          await _initializeCouponsForUser();
        }
        Get.offAll(() => HomePage());
      } else {
        error.value = "No se pudo obtener la información del usuario después del login.";
        throw Exception(error.value);
      }
    } catch (e) {
      print("[AUTH_CTRL.login] Error: $e");
      // ... (tu manejo de errores existente) ...
      appwriteUser.value = null;
      localUser.value = null; // Limpiar también
      profileImageUrl.value = '';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String email, String password, String name) async {
    isLoading.value = true;
    error.value = '';
    try {
      appwrite_auth_models.User newUserAccount = await _authRepository.createAccount(
          email: email, password: password, name: name);
      
      // Crear perfil público en usersCollectionId
      await _userRepository.createOrUpdatePublicUserProfile(
        userId: newUserAccount.$id,
        name: name, 
        email: email,
        profileImageId: null, // Sin foto de perfil al registrarse
        defaultAddress: null, // Sin dirección al registrarse
      );

      await login(email, password); // login se encargará de cargar localUser y navegar
    } catch (e) {
      print("[AUTH_CTRL.register] Error: $e");
      // ... (tu manejo de errores existente) ...
      appwriteUser.value = null;
      localUser.value = null;
      profileImageUrl.value = '';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    error.value = '';
    try {
      await _authRepository.logout();
    } catch (e) {
      print("[AUTH_CTRL.logout] Error al cerrar sesión en Appwrite: $e");
    } finally {
      appwriteUser.value = null;
      localUser.value = null; // Limpiar datos locales
      profileImageUrl.value = '';
      isLoading.value = false;
      Get.offAll(() => LoginPage());
    }
  }

  Future<bool> updateProfileName(String newName, {bool showLoadingIndicator = true}) async {
    if (appwriteUser.value == null) {
      error.value = "Usuario no autenticado.";
      return false;
    }
    if (showLoadingIndicator) isLoading.value = true;
    error.value = '';
    try {
      final String oldName = appwriteUser.value!.name;
      final String userId = appwriteUser.value!.$id;
      final String userEmail = appwriteUser.value!.email;

      // Actualizar nombre en Appwrite Auth
      /*appwrite_auth_models.User updatedAuthAccount =*/ await _authRepository.updateUserName(newName);
      
      // Actualizar nombre en el perfil público de la colección 'users'
      // Obtener el ID de la foto de perfil y dirección actual del localUser o prefs
      final String? currentProfileImageId = localUser.value?.profileImageId ?? appwriteUser.value?.prefs.data[_profileImageIdKey];
      final String? currentDefaultAddress = localUser.value?.defaultAddress;

      UserModel updatedLocalUser = await _userRepository.createOrUpdatePublicUserProfile(
        userId: userId,
        name: newName,
        email: userEmail,
        profileImageId: currentProfileImageId,
        defaultAddress: currentDefaultAddress,
      );
      
      updateLocalUser(updatedLocalUser); // Actualizar el modelo local
      appwriteUser.value = await _authRepository.account.get(); // Refrescar appwriteUser

      if (oldName != newName) {
        print("[AUTH_CTRL.updateProfileName] Name changed from '$oldName' to '$newName'. Updating listings...");
        await _gameListingController.updateSellerNameForUserListings(userId, newName);
      }
      return true;
    } catch (e) {
      print("[AUTH_CTRL.updateProfileName] Error: $e");
      error.value = e is AppwriteException ? (e.message ?? "Error al actualizar nombre.") : "Error al actualizar el nombre.";
      return false;
    } finally {
      if (showLoadingIndicator) isLoading.value = false;
    }
  }

  Future<bool> updateProfilePicture(File imageFile, {bool showLoadingIndicator = true}) async {
    if (appwriteUser.value == null) {
      error.value = "Usuario no autenticado.";
      return false;
    }
    final String userId = appwriteUser.value!.$id;
    // Usar el nombre y email del localUser o appwriteUser más actual
    final String userName = localUser.value?.username ?? appwriteUser.value!.name;
    final String userEmail = localUser.value?.email ?? appwriteUser.value!.email;
    final String? userAddress = localUser.value?.defaultAddress;


    if (showLoadingIndicator) isLoading.value = true;
    error.value = '';

    try {
      final String? oldProfileImageId = localUser.value?.profileImageId ?? appwriteUser.value?.prefs.data[_profileImageIdKey];

      final String? newProfileImageId = await _authRepository.uploadProfilePicture(imageFile, userId);
      if (newProfileImageId == null) {
        error.value = "No se pudo subir la nueva foto de perfil.";
        throw Exception(error.value);
      }

      // Actualizar prefs en Appwrite Auth
      await _authRepository.updateUserPrefs({_profileImageIdKey: newProfileImageId});
      
      // Actualizar perfil público en la colección 'users'
      UserModel updatedLocalUserDoc = await _userRepository.createOrUpdatePublicUserProfile(
        userId: userId,
        name: userName,
        email: userEmail,
        profileImageId: newProfileImageId,
        defaultAddress: userAddress,
      );
      
      // Actualizar estado local
      updateLocalUser(updatedLocalUserDoc);
      appwriteUser.value = await _authRepository.account.get(); // Refrescar appwriteUser
      _loadProfilePictureFromPrefs(appwriteUser.value!.prefs.data); // Esto actualizará profileImageUrl


      if (oldProfileImageId != null && oldProfileImageId.isNotEmpty && oldProfileImageId != newProfileImageId) {
        try {
          await _authRepository.deleteProfilePicture(oldProfileImageId);
        } catch (deleteError) {
          print("[AUTH_CTRL.updateProfilePicture] Error borrando foto antigua (no crítico): $deleteError");
        }
      }
      return true;
    } catch (e) {
      print("[AUTH_CTRL.updateProfilePicture] Error: $e");
      if (error.value.isEmpty) {
          error.value = e is AppwriteException ? (e.message ?? "Error al actualizar foto.") : "Error al actualizar la foto de perfil.";
      }
      return false;
    } finally {
      if (showLoadingIndicator) isLoading.value = false;
    }
  }


  Future<File?> pickProfileImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: source, imageQuality: 70, maxWidth: 512, maxHeight: 512,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print("Error al seleccionar imagen de perfil: $e");
      Get.snackbar("Error de Imagen", "No se pudo seleccionar la imagen: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
    return null;
  }

  // ... (tus métodos de cupones existentes) ...
  Future<void> _initializeCouponsForUser() async {
    if (appwriteUser.value == null) return;
    print("[AUTH_CTRL._initializeCouponsForUser] Initializing coupons...");

    List<Map<String, dynamic>> initialCoupons =
        List.generate(10, (index) {
      return {
        'id': 'WELCOME10_${appwriteUser.value!.$id}_${index + 1}',
        'discount': 0.10,
        'description': '10% Descuento de Bienvenida #${index + 1}',
        'used': false,
      };
    });
    try {
      Map<String, dynamic> currentPrefs = Map<String, dynamic>.from(appwriteUser.value!.prefs.data ?? {});
      currentPrefs['coupons'] = initialCoupons;
      await _authRepository.updateUserPrefs(currentPrefs);
      // Recargar appwriteUser para tener las prefs actualizadas
      appwrite_auth_models.User? updatedUser = await _authRepository.account.get();
      if (updatedUser != null) {
        appwriteUser.value = updatedUser;
      }
    } catch (e) {
      print("[AUTH_CTRL._initializeCouponsForUser] Error initializing coupons: $e");
    }
  }

  Future<bool> useCoupon(String couponId) async {
    if (appwriteUser.value == null || appwriteUser.value!.prefs.data == null) {
      Get.snackbar("Error", "Usuario no encontrado o sin preferencias.");
      return false;
    }
    isLoading.value = true;
    List<dynamic>? couponsDynamic = appwriteUser.value!.prefs.data['coupons'];
    if (couponsDynamic == null) {
        Get.snackbar("Error", "No se encontraron cupones.");
        isLoading.value = false;
        return false;
    }
    List<Map<String, dynamic>> coupons = couponsDynamic.map((c) => Map<String, dynamic>.from(c as Map)).toList();
    int couponIndex = coupons.indexWhere((c) => c['id'] == couponId && c['used'] == false);

    if (couponIndex != -1) {
      coupons[couponIndex]['used'] = true;
      try {
        Map<String, dynamic> currentPrefs = Map<String, dynamic>.from(appwriteUser.value!.prefs.data);
        currentPrefs['coupons'] = coupons;
        await _authRepository.updateUserPrefs(currentPrefs);
        await reloadUser(); 
        isLoading.value = false;
        return true;
      } catch (e) {
        print("Error al actualizar preferencias de cupón: $e");
        Get.snackbar("Error", "No se pudo actualizar el cupón.");
        isLoading.value = false;
        return false;
      }
    } else {
      Get.snackbar("Error", "Cupón no válido o ya utilizado.");
      isLoading.value = false;
      return false;
    }
  }

  List<Map<String, dynamic>> get availableCoupons {
    if (appwriteUser.value != null && appwriteUser.value!.prefs.data != null && appwriteUser.value!.prefs.data.containsKey('coupons')) {
      List<dynamic> couponsDynamic = appwriteUser.value!.prefs.data['coupons'];
      if (couponsDynamic is List) {
        return couponsDynamic
            .map((c) => Map<String, dynamic>.from(c as Map))
            .where((coupon) => coupon['used'] == false)
            .toList();
      }
    }
    return [];
  }

  String? get currentUserId => appwriteUser.value?.$id;
  String? get currentUserName => localUser.value?.username ?? appwriteUser.value?.name; // Prioriza nombre de UserModel
  String? get currentUserEmail => appwriteUser.value?.email;
  bool get isUserLoggedIn => appwriteUser.value != null;
  String? get currentUserDefaultAddress => localUser.value?.defaultAddress; // Getter para la dirección
}