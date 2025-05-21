// lib/controllers/auth_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:proyecto_final/data/repositories/auth_repository.dart';
import 'package:proyecto_final/presentation/pages/home_page.dart';
import 'package:proyecto_final/presentation/pages/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/data/repositories/user_repository.dart'; // IMPORTANTE

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<appwrite_models.User?> appwriteUser = Rx(null);

  final RxString profileImageUrl = ''.obs;
  final String _profileImageIdKey = 'profileImageId';

  // Dependencias
  late final GameListingController _gameListingController;
  late final UserRepository _userRepository;


  AuthController(this._authRepository) {
    // Inicializar otras dependencias aquí si se obtienen con Get.find()
    // Es más seguro hacer Get.find en onInit o pasarlas por constructor si es crítico en la construcción.
    // Pero para _gameListingController y _userRepository, podemos hacerlo en onInit o como late final.
  }

  @override
  void onInit() {
    super.onInit();
    _gameListingController = Get.find<GameListingController>();
    _userRepository = Get.find<UserRepository>();
    _loadCurrentUserOnStartup();
  }


  Future<void> _loadCurrentUserOnStartup({bool showGlobalLoading = true}) async {
    if (showGlobalLoading) isLoading.value = true;
    error.value = '';
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        appwrite_models.User? fetchedUser = await _authRepository.account.get();
        if (fetchedUser != null) {
          appwriteUser.value = fetchedUser;
          _loadProfilePictureFromPrefs(fetchedUser.prefs.data);
          if (fetchedUser.prefs.data == null || !fetchedUser.prefs.data.containsKey('coupons')) {
            await _initializeCouponsForUser();
          }
        } else {
          appwriteUser.value = null;
          profileImageUrl.value = '';
        }
      } else {
        appwriteUser.value = null;
        profileImageUrl.value = '';
      }
    } catch (e) {
      print("[AUTH_CTRL._loadCurrentUserOnStartup] Error cargando usuario: $e");
      appwriteUser.value = null;
      profileImageUrl.value = '';
    } finally {
      if (showGlobalLoading) isLoading.value = false;
    }
  }

  void _loadProfilePictureFromPrefs(Map<String, dynamic>? prefsData) {
    profileImageUrl.value = '';
    if (prefsData != null && prefsData.containsKey(_profileImageIdKey)) {
      final String? fileId = prefsData[_profileImageIdKey];
      if (fileId != null && fileId.isNotEmpty) {
        profileImageUrl.value = _authRepository.getProfilePictureUrl(fileId);
      }
    }
  }

  Future<void> reloadUser() async {
    print("[AUTH_CTRL.reloadUser] Recargando datos del usuario...");
    await _loadCurrentUserOnStartup(showGlobalLoading: false);
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    error.value = '';
    try {
      await _authRepository.login(email: email, password: password);
      appwrite_models.User? fetchedUser = await _authRepository.account.get();
      if (fetchedUser != null) {
        appwriteUser.value = fetchedUser;
        _loadProfilePictureFromPrefs(fetchedUser.prefs.data);
        if (fetchedUser.prefs.data == null || !fetchedUser.prefs.data.containsKey('coupons')) {
           await _initializeCouponsForUser(); // Asegurar cupones en login también
        }
        Get.offAll(() => HomePage());
      } else {
        error.value = "No se pudo obtener la información del usuario después del login.";
        throw Exception(error.value);
      }
    } catch (e) {
      // ... (manejo de errores como estaba)
      print("[AUTH_CTRL.login] Error: $e");
      if (e is AppwriteException) {
        if (e.code == 401) { error.value = "Correo o contraseña incorrectos."; }
        else if (e.code == 400 && e.message != null && e.message!.toLowerCase().contains("invalid email")){ error.value = "El formato del correo no es válido.";}
        else { error.value = "Error de Appwrite (login): ${e.message ?? e.type} (Código: ${e.code})"; }
      } else if (e.toString().contains("No se pudo obtener la información")) { /* Ya está en error.value */ }
      else { error.value = "Error de inicio de sesión. Intenta de nuevo."; }
      appwriteUser.value = null;
      profileImageUrl.value = '';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String email, String password, String name) async {
    isLoading.value = true;
    error.value = '';
    try {
      appwrite_models.User newUserAccount = await _authRepository.createAccount(
          email: email, password: password, name: name);
      
      // Crear perfil público en usersCollectionId
      // Al registrarse, no hay foto de perfil aún, así que profileImageId es null.
      await _userRepository.createOrUpdatePublicUserProfile(
          userId: newUserAccount.$id,
          name: name, // El nombre proporcionado durante el registro
          email: email,
          profileImageId: null // No hay imagen de perfil al registrarse
      );

      await login(email, password); // login se encargará de inicializar cupones y navegar
    } catch (e) {
      // ... (manejo de errores como estaba)
       print("[AUTH_CTRL.register] Error: $e");
      if (error.value.isEmpty) { // Solo si error no fue seteado por login()
        if (e is AppwriteException) {
          if (e.code == 409) { error.value = "Ya existe una cuenta con este correo electrónico."; }
          else if (e.code == 400 && e.message != null && e.message!.toLowerCase().contains("password")){ error.value = "La contraseña debe tener al menos 8 caracteres.";}
          else if (e.code == 400 && e.message != null && e.message!.toLowerCase().contains("email")){ error.value = "El formato del correo no es válido.";}
          else { error.value = "Error de registro (Appwrite): ${e.message ?? e.type} (Código: ${e.code})"; }
        } else { error.value = "Error de registro. Intenta de nuevo."; }
      }
      appwriteUser.value = null;
      profileImageUrl.value = '';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    // ... (como estaba)
    isLoading.value = true;
    error.value = '';
    try {
      await _authRepository.logout();
    } catch (e) {
      print("[AUTH_CTRL.logout] Error al cerrar sesión en Appwrite: $e");
    } finally {
      appwriteUser.value = null;
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
      final String userEmail = appwriteUser.value!.email; // Guardar antes de actualizar

      appwrite_models.User updatedAccount = await _authRepository.updateUserName(newName);
      // appwriteUser.value = updatedAccount; // Actualizar el usuario local con el de Account

      // Obtener el ID de la foto de perfil actual de las preferencias del usuario actualizado
      final String? profileImageIdFromPrefs = updatedAccount.prefs.data[_profileImageIdKey];

      // Actualizar/Crear el perfil público en la colección 'users'
      await _userRepository.createOrUpdatePublicUserProfile(
          userId: userId,
          name: newName, // Nombre nuevo
          email: userEmail, // Email (no debería cambiar aquí)
          profileImageId: profileImageIdFromPrefs
      );
      
      // Es importante recargar el usuario de AuthController para que tenga los datos de Account Y las prefs actualizadas
      // después de la actualización del perfil público si este afecta a cómo se lee el usuario.
      // O, simplemente, asegurar que appwriteUser.value se actualice con el resultado de account.get() o similar.
      appwriteUser.value = await _authRepository.account.get(); // Recargar para tener el estado más fresco de Account

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
    final String userName = appwriteUser.value!.name; // Guardar antes
    final String userEmail = appwriteUser.value!.email; // Guardar antes

    if (showLoadingIndicator) isLoading.value = true;
    error.value = '';

    try {
      final String? oldProfileImageId = appwriteUser.value?.prefs.data[_profileImageIdKey];

      final String? newProfileImageId = await _authRepository.uploadProfilePicture(imageFile, userId);
      if (newProfileImageId == null) {
        error.value = "No se pudo subir la nueva foto de perfil.";
        throw Exception(error.value);
      }

      appwrite_models.User updatedAccount = await _authRepository.updateUserPrefs({_profileImageIdKey: newProfileImageId});
      // appwriteUser.value = updatedAccount; // Actualizar con el usuario de Account
      // _loadProfilePictureFromPrefs(updatedAccount.prefs.data);

      // Actualizar/Crear el perfil público en la colección 'users'
      await _userRepository.createOrUpdatePublicUserProfile(
          userId: userId,
          name: userName, // Usar el nombre que ya tenía la cuenta
          email: userEmail,
          profileImageId: newProfileImageId // El nuevo ID de la foto
      );
      
      // Recargar el usuario para reflejar cambios en prefs y refrescar la URL de la imagen
      appwriteUser.value = await _authRepository.account.get();
      _loadProfilePictureFromPrefs(appwriteUser.value!.prefs.data);


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
    // ... (como estaba)
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

  Future<void> _initializeCouponsForUser() async {
    // ... (como estaba)
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
      appwrite_models.User? updatedUser = await _authRepository.account.get();
      if (updatedUser != null) {
        appwriteUser.value = updatedUser;
      }
    } catch (e) {
      print("[AUTH_CTRL._initializeCouponsForUser] Error initializing coupons: $e");
    }
  }

  Future<bool> useCoupon(String couponId) async {
    // ... (como estaba)
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
    // ... (como estaba)
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
  String? get currentUserName => appwriteUser.value?.name;
  String? get currentUserEmail => appwriteUser.value?.email;
  bool get isUserLoggedIn => appwriteUser.value != null;
}