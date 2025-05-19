// lib/controllers/auth_controller.dart
import 'package:get/get.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:proyecto_final/data/repositories/auth_repository.dart';
import 'package:proyecto_final/presentation/pages/home_page.dart';
import 'package:proyecto_final/presentation/pages/login_page.dart';
// import 'package:proyecto_final/presentation/pages/start_page.dart'; // Podrías redirigir a StartPage en algunos casos

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<appwrite_models.User?> appwriteUser = Rx(null);

  AuthController(this._authRepository) {
    _loadCurrentUserOnStartup();
  }

  Future<void> _loadCurrentUserOnStartup() async {
    print("[AUTH_CTRL._loadCurrentUserOnStartup] Intentando cargar usuario al inicio...");
    isLoading.value = true; // Indicar carga al inicio
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
    } finally {
      isLoading.value = false;
      print("[AUTH_CTRL._loadCurrentUserOnStartup] Fin. appwriteUser es: ${appwriteUser.value == null ? 'null' : 'NO null (ID: ${appwriteUser.value!.$id})'}");
    }
  }

  Future<bool> checkAuthStatusAndNavigate() async {
    // Este método es más explícito para el arranque de la app
    isLoading.value = true;
    error.value = '';
    bool loggedIn = false;
    print("[AUTH_CTRL.checkAuthStatusAndNavigate] Verificando autenticación...");
    try {
      loggedIn = await _authRepository.isLoggedIn();
      print("[AUTH_CTRL.checkAuthStatusAndNavigate] isLoggedIn: $loggedIn");
      if (loggedIn) {
        appwrite_models.User? fetchedUser = await _authRepository.account.get();
        if (fetchedUser != null) {
          print("[AUTH_CTRL.checkAuthStatusAndNavigate] Usuario Appwrite cargado: ID=${fetchedUser.$id}, Name=${fetchedUser.name}, Email=${fetchedUser.email}");
          appwriteUser.value = fetchedUser;
          Get.offAll(() => HomePage()); // Ir a HomePage si está logueado
        } else {
          print("[AUTH_CTRL.checkAuthStatusAndNavigate] _authRepository.account.get() devolvió null.");
          appwriteUser.value = null;
          loggedIn = false; // Considerar como no logueado si no se puede obtener el usuario
          Get.offAll(() => LoginPage()); // Ir a LoginPage si no se pudo obtener el usuario
        }
      } else {
        appwriteUser.value = null;
        print("[AUTH_CTRL.checkAuthStatusAndNavigate] No hay sesión activa.");
        Get.offAll(() => LoginPage()); // Ir a LoginPage si no está logueado
      }
    } catch (e) {
      print("[AUTH_CTRL.checkAuthStatusAndNavigate] Error verificando auth: $e");
      error.value = "Error al verificar el estado de sesión.";
      loggedIn = false;
      appwriteUser.value = null;
      Get.offAll(() => LoginPage()); // Ir a LoginPage en caso de error
    } finally {
      isLoading.value = false;
      print("[AUTH_CTRL.checkAuthStatusAndNavigate] Fin. appwriteUser es: ${appwriteUser.value == null ? 'null' : 'NO null (ID: ${appwriteUser.value!.$id})'}");
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
         // Si no se puede obtener el usuario, es un problema.
        throw Exception("No se pudo obtener la información del usuario después del login.");
      }
      
      Get.offAll(() => HomePage());
    } catch (e) {
      print("[AUTH_CTRL.login] Error durante el proceso de login: $e");
      if (e is AppwriteException) {
        if (e.code == 401) {
          error.value = "Correo o contraseña incorrectos.";
        } else if (e.code == 400 && e.message != null && e.message!.toLowerCase().contains("invalid email")){
           error.value = "El formato del correo no es válido.";
        } else {
          error.value = "Error de Appwrite (login): ${e.message ?? e.type} (Código: ${e.code})";
        }
      } else {
        error.value = "Error de inicio de sesión: ${e.toString()}";
      }
      appwriteUser.value = null;
    } finally {
      isLoading.value = false;
      print("[AUTH_CTRL.login] Proceso de login finalizado. appwriteUser es: ${appwriteUser.value == null ? 'null' : (appwriteUser.value!.$id)}");
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
      // Appwrite usualmente crea una sesión después del registro, pero es bueno confirmarlo.
      await login(email, password); 
    } catch (e) {
      print("[AUTH_CTRL.register] Error durante el proceso de registro: $e");
      if (error.value.isNotEmpty) {
        // Error ya fue seteado por el login interno
      } else if (e is AppwriteException) {
        if (e.code == 409) { 
          error.value = "Ya existe una cuenta con este correo electrónico.";
        } else if (e.code == 400 && e.message != null && e.message!.toLowerCase().contains("password")){
           error.value = "La contraseña debe tener al menos 8 caracteres.";
        } else if (e.code == 400 && e.message != null && e.message!.toLowerCase().contains("email")){
           error.value = "El formato del correo no es válido.";
        }
         else {
          error.value = "Error de registro (Appwrite): ${e.message ?? e.type} (Código: ${e.code})";
        }
      } else {
        error.value = "Error de registro: ${e.toString()}";
      }
      appwriteUser.value = null; 
    } finally {
      isLoading.value = false;
      print("[AUTH_CTRL.register] Proceso de registro finalizado. appwriteUser es: ${appwriteUser.value == null ? 'null' : (appwriteUser.value!.$id)}");
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    error.value = '';
    print("[AUTH_CTRL.logout] Intentando cerrar sesión...");
    try {
      await _authRepository.logout();
      print("[AUTH_CTRL.logout] Sesión eliminada de Appwrite.");
      appwriteUser.value = null;
      Get.offAll(() => LoginPage()); // O StartPage() si prefieres
    } catch (e) {
      print("[AUTH_CTRL.logout] Error al cerrar sesión: $e");
      // Aunque haya error, intentamos limpiar localmente y navegar a Login
      appwriteUser.value = null; 
      Get.offAll(() => LoginPage());
    } finally {
      isLoading.value = false;
      print("[AUTH_CTRL.logout] Proceso de logout finalizado. appwriteUser es: ${appwriteUser.value == null ? 'null' : 'NO null'}");
    }
  }

  String? get currentUserId => appwriteUser.value?.$id;
  String? get currentUserName => appwriteUser.value?.name;
  String? get currentUserEmail => appwriteUser.value?.email;
  bool get isUserLoggedIn => appwriteUser.value != null;
}
