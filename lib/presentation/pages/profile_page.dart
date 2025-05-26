// lib/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/controllers/user_controller.dart'; // <--- IMPORTACIÓN AÑADIDA/ASEGURADA
import 'package:proyecto_final/presentation/pages/edit_profile_page.dart';
import 'package:proyecto_final/presentation/pages/login_page.dart';
import 'package:proyecto_final/presentation/pages/user_activity_page.dart';
// import 'package:proyecto_final/presentation/pages/user_listings_page.dart'; // Si tienes esta página

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthController _authController = Get.find();
  final UserController _userController = Get.find();
  final GameListingController _gameListingCtrlForDate = Get.find<GameListingController>();

  void _showEditLocationDialog(BuildContext context) {
    final TextEditingController addressController = TextEditingController();
    addressController.text = _authController.localUser.value?.defaultAddress ?? '';

    Get.defaultDialog(
      title: "Editar Mi Ubicación",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: addressController,
            decoration: const InputDecoration(
              labelText: "Mi Dirección Predeterminada",
              hintText: "Ej: Cl 18 #32, Pasto, Nariño",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 8),
          Text(
            "Esta dirección se usará para la entrega de juegos y el cálculo de puntos de encuentro.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          )
        ],
      ),
      confirm: Obx(() => _userController.isLoadingUpdate.value
          ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: () {
                _userController.updateUserDefaultLocation(addressController.text);
                Get.back();
              },
              child: const Text("Guardar"),
            )),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text("Cancelar"),
      ),
    );
  }

  String _formatCouponIdForDisplay(dynamic rawCouponId) {
    if (rawCouponId is String && rawCouponId.isNotEmpty) {
      int len = rawCouponId.length;
      int endIndex = len ~/ 2; 
      if (endIndex == 0 && len > 0) endIndex = 1;
      if (len > 6 && endIndex < 3) endIndex = 3;
      if (endIndex > 8) endIndex = 8;
      endIndex = endIndex.clamp(0, len);
      String part = rawCouponId.substring(0, endIndex);
      return rawCouponId.length > endIndex ? "$part..." : part;
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar Nombre/Foto',
            onPressed: () async {
              await Get.to(() => const EditProfilePage());
              _authController.reloadUser(); 
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_authController.isLoading.value && _authController.appwriteUser.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_authController.appwriteUser.value == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.currentRoute == '/ProfilePage' || Get.currentRoute == runtimeType.toString()) {
              Get.offAll(() => LoginPage());
            }
          });
          return const Center(child: Text("Usuario no autenticado. Redirigiendo..."));
        }
        
        final appwriteAuthUser = _authController.appwriteUser.value!;
        final userModel = _authController.localUser.value;

        final String displayName = userModel?.username ?? appwriteAuthUser.name;
        final String displayEmail = appwriteAuthUser.email;
        final String displayProfilePicUrl = _authController.profileImageUrl.value;
        final String displayAddress = userModel?.defaultAddress ?? "No establecida";
        final String displayCoords = (userModel?.latitude != null && userModel?.longitude != null)
            ? "Lat: ${userModel!.latitude!.toStringAsFixed(4)}, Lon: ${userModel.longitude!.toStringAsFixed(4)}"
            : "Coordenadas no disponibles";
        final List<Map<String, dynamic>> availableCoupons = _authController.availableCoupons;

        return RefreshIndicator(
          onRefresh: () => _authController.reloadUser(),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  backgroundImage: (displayProfilePicUrl.isNotEmpty && !displayProfilePicUrl.contains("placehold.co"))
                      ? NetworkImage(displayProfilePicUrl)
                      : null,
                  child: (displayProfilePicUrl.isEmpty || displayProfilePicUrl.contains("placehold.co"))
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: TextStyle(fontSize: 50, color: Theme.of(context).colorScheme.onSurfaceVariant))
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  displayEmail,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.verified_user_outlined, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Estado del Correo'),
                        subtitle: Text(appwriteAuthUser.emailVerification ? 'Verificado' : 'No Verificado'),
                      ),
                      ListTile(
                        leading: Icon(Icons.date_range_outlined, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Fecha de Registro'),
                        subtitle: Text(_gameListingCtrlForDate.formatDate(appwriteAuthUser.registration)),
                      ),
                      ListTile(
                        leading: Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Mi Ubicación Predeterminada'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayAddress),
                            if (userModel?.latitude != null && userModel?.longitude != null) 
                              Text(displayCoords, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: "Editar ubicación",
                          onPressed: () => _showEditLocationDialog(context),
                        ),
                        isThreeLine: userModel?.latitude != null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(Icons.history_edu_outlined, color: Theme.of(context).colorScheme.secondary),
                  title: const Text('Mis Compras y Ventas'),
                  subtitle: const Text('Ver historial de actividad'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Get.to(() => const UserActivityPage());
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ExpansionTile(
                  leading: Icon(Icons.confirmation_number_outlined, color: Colors.amber[700]),
                  title: Text('Cupones Disponibles (${availableCoupons.length})'),
                  subtitle: const Text('Toca para ver tus cupones de descuento'),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: availableCoupons.isEmpty
                      ? [const Padding(padding: EdgeInsets.all(8.0), child: Text("No tienes cupones disponibles."))]
                      : availableCoupons.map((coupon) {
                          final String discountDisplay = (((coupon['discount'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(0);
                          final String couponIdDisplay = _formatCouponIdForDisplay(coupon['id']);
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                            leading: Icon(Icons.local_offer_outlined, size: 20, color: Colors.green[600]),
                            title: Text(coupon['description'] ?? 'Cupón de Descuento'),
                            subtitle: Text("Descuento: $discountDisplay% - ID: $couponIdDisplay"),
                          );
                        }).toList(),
                ),
              ),
              const SizedBox(height: 20),
               ListTile(
                  leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                  title: Text('Cerrar Sesión', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () async {
                    await _authController.logout();
                  },
                ),
            ],
          ),
        );
      }),
    );
  }
}