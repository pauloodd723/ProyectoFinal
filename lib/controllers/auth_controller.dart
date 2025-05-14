// lib/controllers/auth_controller.dart
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models; // Para el modelo User de Appwrite
import 'package:proyecto_final/data/repositories/auth_repository.dart';
import 'package:proyecto_final/presentation/pages/home_page.dart';
import 'package:proyecto_final/presentation/pages/login_page.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Variable para almacenar el usuario de Appwrite actual
  final Rx<appwrite_models.User?> appwriteUser = Rx(null);

  AuthController(this._authRepository) {
    // Intenta cargar el usuario actual al iniciar el controlador
    _loadCurrentUserOnStartup();
  }

  Future<void> _loadCurrentUserOnStartup() async {
    print("[AUTH_CTRL._loadCurrentUserOnStartup] Intentando cargar usuario al inicio...");
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      print("[AUTH_CTRL._loadCurrentUserOnStartup] isLoggedIn: $isLoggedIn");
      if (isLoggedIn) {
        appwrite_models.User? fetchedUser = await _authRepository.account.get();
        if (fetchedUser != null) {
          print("[AUTH_CTRL._loadCurrentUserOnStartup] Usuario Appwrite cargado: ID=${fetchedUser.$id}, Name=${fetchedUser.name}, Email=${fetchedUser.email}");
          appwriteUser.value = fetchedUser;
        } else {
          print("[AUTH_CTRL._loadCurrentUserOnStartup] _authRepository.account.get() devolvió null.");
          appwriteUser.value = null;
        }
      } else {
        appwriteUser.value = null;
        print("[AUTH_CTRL._loadCurrentUserOnStartup] No hay sesión activa.");
      }
    } catch (e) {
      print("[AUTH_CTRL._loadCurrentUserOnStartup] Error cargando usuario: $e");
      appwriteUser.value = null;
    }
    print("[AUTH_CTRL._loadCurrentUserOnStartup] Fin. appwriteUser es: ${appwriteUser.value == null ? 'null' : 'NO null (ID: ${appwriteUser.value!.$id})'}");
  }

  Future<bool> checkAuth() async {
    isLoading.value = true;
    error.value = '';
    bool loggedIn = false;
    print("[AUTH_CTRL.checkAuth] Verificando autenticación...");
    try {
      loggedIn = await _authRepository.isLoggedIn();
      print("[AUTH_CTRL.checkAuth] isLoggedIn: $loggedIn");
      if (loggedIn) {
        appwrite_models.User? fetchedUser = await _authRepository.account.get();
        if (fetchedUser != null) {
          print("[AUTH_CTRL.checkAuth] Usuario Appwrite cargado: ID=${fetchedUser.$id}, Name=${fetchedUser.name}, Email=${fetchedUser.email}");
          appwriteUser.value = fetchedUser;
        } else {
          print("[AUTH_CTRL.checkAuth] _authRepository.account.get() devolvió null.");
          appwriteUser.value = null;
        }
      } else {
        appwriteUser.value = null;
        print("[AUTH_CTRL.checkAuth] No hay sesión activa.");
      }
    } catch (e) {
      print("[AUTH_CTRL.checkAuth] Error verificando auth: $e");
      error.value = "Error al verificar el estado de sesión.";
      loggedIn = false;
      appwriteUser.value = null;
    } finally {
      isLoading.value = false;
      print("[AUTH_CTRL.checkAuth] Fin. appwriteUser es: ${appwriteUser.value == null ? 'null' : 'NO null (ID: ${appwriteUser.value!.$id})'}");
    }
    return loggedIn;
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    error.value = '';
    print("[AUTH_CTRL.login] Intentando iniciar sesión para: $email");
    try {
      await _authRepository.login(email: email, password: password);
      print("[AUTH_CTRL.login] _authRepository.login exitoso (sesión creada).");
      
      appwrite_models.User? fetchedUser = await _authRepository.account.get();
      if (fetchedUser != null) {
        print("[AUTH_CTRL.login] Usuario Appwrite obtenido: ID=${fetchedUser.$id}, Name=${fetchedUser.name}, Email=${fetchedUser.email}");
        appwriteUser.value = fetchedUser;
      } else {
        print("[AUTH_CTRL.login] _authRepository.account.get() devolvió null después de crear sesión.");
        appwriteUser.value = null;
      }
      
      Get.offAll(() => HomePage());
    } catch (e) {
      print("[AUTH_CTRL.login] Error durante el proceso de login: $e");
      if (e is AppwriteException) {
        if (e.code == 401) { // Código para credenciales inválidas o usuario no encontrado
          error.value = "Correo o contraseña incorrectos.";
        } else {
          error.value = "Error de Appwrite (login): ${e.message ?? e.type} (Código: ${e.code})";
        }
      } else {
        error.value = "Error de inicio de sesión: ${e.toString()}";
      }
      appwriteUser.value = null; // Asegurar que sea null si hay error
    } finally {
      isLoading.value = false;
      print("[AUTH_CTRL.login] Proceso de login finalizado. appwriteUser es: ${appwriteUser.value == null ? 'null' : 'NO null (ID: ${appwriteUser.value!.$id})'}");
    }
  }

  Future<void> register(String email, String password, String name) async {
    isLoading.value = true;
    error.value = '';
    print("[AUTH_CTRL.register] Intentando registrar: $email, Nombre: $name");
    try {
      await _authRepository.createAccount(
        email: email,
        password: password,
        name: name,
      );
      print("[AUTH_CTRL.register] _authRepository.createAccount exitoso.");
      // Después de registrar, intentar login para obtener la sesión y los datos del usuario
      await login(email, password); // login ya tiene prints y actualiza appwriteUser
    } catch (e) {
      print("[AUTH_CTRL.register] Error durante el proceso de registro: $e");
      // Si login() dentro de register falla, ya habrá establecido error.value
      if (error.value.isNotEmpty) {
        // Error ya fue seteado por el login interno
      } else if (e is AppwriteException) {
        if (e.code == 409) { // Conflicto - Usualmente significa que el usuario ya existe
          error.value = "Ya existe una cuenta con este correo electrónico.";
        } else {
          error.value = "Error de registro (Appwrite): ${e.message ?? e.type} (Código: ${e.code})";
        }
      } else {
        error.value = "Error de registro: ${e.toString()}";
      }
      appwriteUser.value = null; // Asegurar que sea null si hay error
    } finally {
      isLoading.value = false;
      print("[AUTH_CTRL.register] Proceso de registro finalizado. appwriteUser es: ${appwriteUser.value == null ? 'null' : 'NO null (ID: ${appwriteUser.value!.$id})'}");
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    error.value = '';
    print("[AUTH_CTRL.logout] Intentando cerrar sesión...");
    try {
      await _authRepository.logout();
      print("[AUTH_CTRL.logout] Sesión eliminada de Appwrite.");
      appwriteUser.value = null; // Limpiar usuario al hacer logout
      Get.offAll(() => LoginPage());
    } catch (e) {
      print("[AUTH_CTRL.logout] Error al cerrar sesión: $e");
      appwriteUser.value = null; // Asegurar que sea null si hay error
      Get.offAll(() => LoginPage()); // Igualmente ir a LoginPage
    } finally {
      isLoading.value = false;
      print("[AUTH_CTRL.logout] Proceso de logout finalizado. appwriteUser es: ${appwriteUser.value == null ? 'null' : 'NO null'}");
    }
  }

  // Getters para usar en otras partes de la app
  String? get currentUserId => appwriteUser.value?.$id;
  String? get currentUserName => appwriteUser.value?.name; // El modelo User de Appwrite tiene 'name'
}
