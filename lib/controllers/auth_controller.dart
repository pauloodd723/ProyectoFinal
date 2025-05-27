import 'dart:io';
import 'package:flutter/material.dart'; 
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_auth_models; 
import 'package:proyecto_final/data/repositories/auth_repository.dart';
import 'package:proyecto_final/presentation/pages/home_page.dart';
import 'package:proyecto_final/presentation/pages/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/data/repositories/user_repository.dart';
import 'package:proyecto_final/model/user_model.dart'; 

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<appwrite_auth_models.User?> appwriteUser = Rx(null); 
  final RxString profileImageUrl = ''.obs; 
  final Rx<UserModel?> localUser = Rx<UserModel?>(null);
  final String _profileImageIdKey = 'profileImageId'; 
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
    print("[AuthController] _fetchLocalUserData para UserModel ID: $userId");
    try {
      localUser.value = await _userRepository.getUserById(userId);
      if (localUser.value != null) {
        print("[AuthController] UserModel local cargado: ${localUser.value!.username}");
        print("  Dirección: ${localUser.value!.defaultAddress}");
        print("  Latitud: ${localUser.value!.latitude}");
        print("  Longitud: ${localUser.value!.longitude}");

        if (localUser.value!.profileImageId != null && localUser.value!.profileImageId!.isNotEmpty) {
           final String localUserPhotoUrl = _authRepository.getProfilePictureUrl(localUser.value!.profileImageId!);
           if (profileImageUrl.value != localUserPhotoUrl) {
             profileImageUrl.value = localUserPhotoUrl;
             print("[AuthController] profileImageUrl actualizada desde localUser.value.profileImageId.");
           }
        } else if (profileImageUrl.value.isNotEmpty && (localUser.value!.profileImageId == null || localUser.value!.profileImageId!.isEmpty)) {

        }
      } else {
         print("[AuthController] No se encontró UserModel local para $userId.");
         if(appwriteUser.value != null && appwriteUser.value!.$id == userId) {
            print("[AuthController] Creando perfil UserModel local para $userId porque no existía.");
            UserModel createdProfile = await _userRepository.createOrUpdatePublicUserProfile(
                userId: appwriteUser.value!.$id,
                name: appwriteUser.value!.name,
                email: appwriteUser.value!.email,
                profileImageId: appwriteUser.value!.prefs.data[_profileImageIdKey], 
                defaultAddress: null, 
                latitude: null,      
                longitude: null,      
            );
            localUser.value = createdProfile; 
            print("[AuthController] UserModel local creado para $userId.");
             if (localUser.value!.profileImageId != null && localUser.value!.profileImageId!.isNotEmpty) {
                profileImageUrl.value = _authRepository.getProfilePictureUrl(localUser.value!.profileImageId!);
             }
         }
      }
    } catch (e) {
      print("[AuthController] Error cargando UserModel local para $userId: $e");
      localUser.value = null; 
    }
  }
  
  void updateLocalUser(UserModel updatedUser) {
    if (appwriteUser.value != null && appwriteUser.value!.$id == updatedUser.$id) {
      localUser.value = updatedUser;
      print("[AuthController] UserModel local ha sido actualizado en AuthController.");
      print("  Nueva Dirección: ${localUser.value?.defaultAddress}");
      print("  Nueva Latitud: ${localUser.value?.latitude}");
      print("  Nueva Longitud: ${localUser.value?.longitude}");

      if (updatedUser.profileImageId != null && updatedUser.profileImageId!.isNotEmpty) {
          final newUrl = _authRepository.getProfilePictureUrl(updatedUser.profileImageId!);
          if (profileImageUrl.value != newUrl) {
            profileImageUrl.value = newUrl;
          }
      } else if (updatedUser.profileImageId == null || updatedUser.profileImageId!.isEmpty) {

           if(profileImageUrl.value.isNotEmpty && !profileImageUrl.value.contains("placehold.co")) {
             profileImageUrl.value = ''; 
           }
      }
    } else {
      print("[AuthController] No se pudo actualizar localUser: IDs no coinciden o appwriteUser (Auth) es null.");
    }
  }

  Future<void> _loadCurrentUserOnStartup({bool showGlobalLoading = true}) async {
    if (showGlobalLoading) isLoading.value = true;
    error.value = '';
    localUser.value = null; 
    profileImageUrl.value = '';

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        appwrite_auth_models.User? fetchedAuthUser = await _authRepository.account.get();
        if (fetchedAuthUser != null) {
          appwriteUser.value = fetchedAuthUser;
          _loadProfilePictureFromPrefs(fetchedAuthUser.prefs.data); 
          await _fetchLocalUserData(fetchedAuthUser.$id); 

          if (fetchedAuthUser.prefs.data == null || !fetchedAuthUser.prefs.data.containsKey('coupons')) {
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

    bool wasLoading = isLoading.value;
    await _loadCurrentUserOnStartup(showGlobalLoading: false);
    if (wasLoading) isLoading.value = true; 
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true; error.value = '';
    try {
      await _authRepository.login(email: email, password: password);
      appwrite_auth_models.User? fetchedAuthUser = await _authRepository.account.get();
      if (fetchedAuthUser != null) {
        appwriteUser.value = fetchedAuthUser;
        _loadProfilePictureFromPrefs(fetchedAuthUser.prefs.data);
        await _fetchLocalUserData(fetchedAuthUser.$id);

        if (fetchedAuthUser.prefs.data == null || !fetchedAuthUser.prefs.data.containsKey('coupons')) {
          await _initializeCouponsForUser();
        }
        Get.offAll(() => HomePage());
      } else {
        error.value = "No se pudo obtener la información del usuario después del login.";
        throw Exception(error.value);
      }
    } catch (e) {
      print("[AUTH_CTRL.login] Error: $e");
      appwriteUser.value = null; localUser.value = null; profileImageUrl.value = '';
      if (e is AppwriteException) {
        if (e.code == 401) { error.value = "Correo o contraseña incorrectos."; }
        else if (e.code == 400 && e.message != null && e.message!.toLowerCase().contains("invalid email")){ error.value = "El formato del correo no es válido.";}
        else { error.value = "Error de Appwrite (login): ${e.message ?? e.type} (Código: ${e.code})"; }
      } else if (!e.toString().contains("No se pudo obtener la información")) {
         error.value = "Error de inicio de sesión. Intenta de nuevo.";
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String email, String password, String name) async {
    isLoading.value = true; error.value = '';
    try {
      appwrite_auth_models.User newUserAccount = await _authRepository.createAccount(
          email: email, password: password, name: name);
      await _userRepository.createOrUpdatePublicUserProfile(
        userId: newUserAccount.$id,
        name: name, 
        email: email,
        profileImageId: null, 
        defaultAddress: null,
        latitude: null,
        longitude: null,
      );

      await login(email, password); 
    } catch (e) {
      print("[AUTH_CTRL.register] Error: $e");
      appwriteUser.value = null; localUser.value = null; profileImageUrl.value = '';
      if (error.value.isEmpty) { 
        if (e is AppwriteException) {
          if (e.code == 409) { error.value = "Ya existe una cuenta con este correo."; }
          else if (e.code == 400 && e.message != null && e.message!.toLowerCase().contains("password")){ error.value = "La contraseña debe tener al menos 8 caracteres.";}
          else if (e.code == 400 && e.message != null && e.message!.toLowerCase().contains("email")){ error.value = "El formato del correo no es válido.";}
          else { error.value = "Error de registro (Appwrite): ${e.message ?? e.type} (Código: ${e.code})"; }
        } else { error.value = "Error de registro. Intenta de nuevo."; }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true; error.value = '';
    try {
      await _authRepository.logout();
    } catch (e) {
      print("[AUTH_CTRL.logout] Error al cerrar sesión en Appwrite: $e");
    } finally {
      appwriteUser.value = null; 
      localUser.value = null;
      profileImageUrl.value = '';
      isLoading.value = false; 
      Get.offAll(() => LoginPage());
    }
  }

  Future<bool> updateProfileName(String newName, {bool showLoadingIndicator = true}) async {
    if (appwriteUser.value == null) { error.value = "Usuario no autenticado."; return false; }
    if (localUser.value == null && appwriteUser.value != null) {
        await _fetchLocalUserData(appwriteUser.value!.$id);
        if (localUser.value == null) {
            error.value = "Datos de perfil local no disponibles. Intenta más tarde.";
            return false;
        }
    } else if (localUser.value == null) {
        error.value = "Datos de perfil local no disponibles.";
        return false;
    }


    if (showLoadingIndicator) isLoading.value = true; error.value = '';
    try {
      final String oldName = localUser.value!.username; 
      final String userId = appwriteUser.value!.$id;
      
      await _authRepository.updateUserName(newName); 
      
      UserModel updatedLocalUser = await _userRepository.createOrUpdatePublicUserProfile(
        userId: userId,
        name: newName, 
        email: localUser.value!.email, 
        profileImageId: localUser.value!.profileImageId, 
        defaultAddress: localUser.value!.defaultAddress, 
        latitude: localUser.value!.latitude,             
        longitude: localUser.value!.longitude,        
      );
      
      updateLocalUser(updatedLocalUser); 
      appwriteUser.value = await _authRepository.account.get(); 

      if (oldName != newName) {
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
    if (appwriteUser.value == null) { error.value = "Usuario no autenticado."; return false; }
     if (localUser.value == null && appwriteUser.value != null) {
        await _fetchLocalUserData(appwriteUser.value!.$id);
        if (localUser.value == null) {
            error.value = "Datos de perfil local no disponibles. Intenta más tarde.";
            return false;
        }
    } else if (localUser.value == null) {
         error.value = "Datos de perfil local no disponibles.";
        return false;
    }
    
    final String userId = appwriteUser.value!.$id;

    if (showLoadingIndicator) isLoading.value = true; error.value = '';
    try {
      final String? oldProfileImageIdOnPrefs = appwriteUser.value?.prefs.data[_profileImageIdKey];
      final String? oldProfileImageIdOnLocal = localUser.value!.profileImageId;
      final String? effectiveOldProfileImageId = oldProfileImageIdOnLocal ?? oldProfileImageIdOnPrefs;
      final String? newProfileImageId = await _authRepository.uploadProfilePicture(imageFile, userId);
      if (newProfileImageId == null) {
        error.value = "No se pudo subir la nueva foto de perfil.";
        throw Exception(error.value);
      }
      await _authRepository.updateUserPrefs({_profileImageIdKey: newProfileImageId});

      UserModel updatedLocalUserDoc = await _userRepository.createOrUpdatePublicUserProfile(
        userId: userId,
        name: localUser.value!.username,
        email: localUser.value!.email,
        profileImageId: newProfileImageId, 
        defaultAddress: localUser.value!.defaultAddress,
        latitude: localUser.value!.latitude,
        longitude: localUser.value!.longitude,
      );
      
      updateLocalUser(updatedLocalUserDoc); 
      appwriteUser.value = await _authRepository.account.get();

      if (effectiveOldProfileImageId != null && effectiveOldProfileImageId.isNotEmpty && effectiveOldProfileImageId != newProfileImageId) {
        try {
          await _authRepository.deleteProfilePicture(effectiveOldProfileImageId);
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
  String? get currentUserName => localUser.value?.username ?? appwriteUser.value?.name;
  String? get currentUserEmail => appwriteUser.value?.email;
  bool get isUserLoggedIn => appwriteUser.value != null;
  String? get currentUserDefaultAddress => localUser.value?.defaultAddress;
  double? get currentUserLatitude => localUser.value?.latitude;
  double? get currentUserLongitude => localUser.value?.longitude;
  String get profilePictureUrl => profileImageUrl.value;
}