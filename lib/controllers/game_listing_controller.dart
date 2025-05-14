// lib/controllers/game_listing_controller.dart
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Importa el paquete intl para DateFormat
import 'package:proyecto_final/data/repositories/game_listing_repository.dart';
import 'package:proyecto_final/model/game_listing_model.dart';
// Asegúrate de que AuthController esté disponible si lo necesitas directamente aquí,
// aunque para formatDate no es necesario.
// import 'package:proyecto_final/controllers/auth_controller.dart';


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
    fetchListings(); // Cargar listados al iniciar

    // Escuchar cambios en searchQuery para buscar automáticamente
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

  Future<void> addListing(GameListingModel newListing, String currentUserId, String currentUserName) async {
    try {
      isLoading.value = true;
      error.value = '';
      // El GameListingModel ya debería tener sellerId y sellerName asignados
      // desde AddListingPage antes de llamar a este método.
      // Si no, asegúrate que newListing los contenga o modifícalo aquí.
      // Por ejemplo: final listingWithSellerInfo = newListing.copyWith(sellerId: currentUserId, sellerName: currentUserName);
      // Y luego usa listingWithSellerInfo.
      await repository.addGameListing(newListing, currentUserId);
      fetchListings(); // Recargar listados después de añadir uno nuevo
    } catch (e) {
      print("[GameListingController] Error al añadir el listado: $e");
      error.value = "Error al añadir el listado: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  // --- NUEVO MÉTODO PARA FORMATEAR FECHA ---
  String formatDate(String dateString) {
    if (dateString.isEmpty) {
      return 'No disponible';
    }
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      // Puedes personalizar el formato como desees.
      // Ejemplos:
      // 'dd/MM/yyyy' -> 14/05/2025
      // 'dd MMM yyyy' -> 14 May 2025
      // 'EEEE, MMMM d, yyyy' -> Wednesday, May 14, 2025
      // 'dd/MM/yyyy, hh:mm a' -> 14/05/2025, 11:28 AM (con AM/PM)
      return DateFormat('dd/MM/yyyy, hh:mm a', 'es_CO').format(dateTime.toLocal()); // 'es_CO' para formato de Colombia si es necesario
    } catch (e) {
      print("[GameListingController] Error formateando fecha '$dateString': $e");
      return dateString; // Devuelve el string original si hay error de parseo
    }
  }
}
