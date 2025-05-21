// lib/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/presentation/pages/edit_profile_page.dart';
import 'package:proyecto_final/presentation/pages/login_page.dart';
import 'package:proyecto_final/presentation/pages/user_activity_page.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Helper para formatear el ID del cupón de forma segura
  String _formatCouponIdForDisplay(dynamic rawCouponId) {
    if (rawCouponId is String && rawCouponId.isNotEmpty) {
      int len = rawCouponId.length;
      int endIndex = len ~/ 2; // Tomar la mitad
      
      // Ajustes para que se vea bien:
      if (endIndex == 0 && len > 0) endIndex = 1; // Si es muy corto, mostrar al menos 1 carácter
      if (len > 6 && endIndex < 3) endIndex = 3;   // Si es más largo, mostrar al menos 3
      if (endIndex > 8) endIndex = 8;             // No mostrar más de 8 caracteres iniciales

      // Asegurarse de no exceder la longitud real
      endIndex = endIndex.clamp(0, len);

      String part = rawCouponId.substring(0, endIndex);
      return rawCouponId.length > endIndex ? "$part..." : part;
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();
    final GameListingController gameListingCtrlForDate = Get.find<GameListingController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar Perfil',
            onPressed: () async {
              await Get.to(() => const EditProfilePage());
              authController.reloadUser(); 
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await authController.logout();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (authController.isLoading.value && authController.appwriteUser.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (authController.appwriteUser.value == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final currentRouteName = Get.currentRoute;
            if (currentRouteName == '/ProfilePage' || currentRouteName == runtimeType.toString()) {
              Get.offAll(() => LoginPage());
            }
          });
          return const Center(
            child: Text("Usuario no disponible. Redirigiendo..."),
          );
        }

        final user = authController.appwriteUser.value!;
        final String profilePicUrl = authController.profileImageUrl.value;
        final List<Map<String, dynamic>> availableCoupons = authController.availableCoupons;

        return RefreshIndicator(
          onRefresh: () => authController.reloadUser(),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: () async {
                       await Get.to(() => const EditProfilePage());
                       authController.reloadUser();
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    backgroundImage: (profilePicUrl.isNotEmpty && !profilePicUrl.contains("placehold.co"))
                        ? NetworkImage(profilePicUrl)
                        : null,
                    child: (profilePicUrl.isEmpty || profilePicUrl.contains("placehold.co"))
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: TextStyle(fontSize: 50, color: Theme.of(context).colorScheme.onSurfaceVariant))
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.name.isNotEmpty ? user.name : "Nombre de Usuario",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  user.email,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.verified_user_outlined, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Estado del Correo'),
                        subtitle: Text(user.emailVerification ? 'Verificado' : 'No Verificado'),
                      ),
                      ListTile(
                        leading: Icon(Icons.date_range_outlined, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Fecha de Registro'),
                        subtitle: Text(user.registration != null ? gameListingCtrlForDate.formatDate(user.registration!) : 'No disponible'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16), 

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: Icon(Icons.confirmation_number_outlined, color: Colors.amber[600]),
                  title: Text('Cupones Disponibles (${availableCoupons.length})'),
                  subtitle: const Text('Toca para ver tus cupones de descuento'),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: availableCoupons.isEmpty
                      ? [const Padding(padding: EdgeInsets.all(8.0), child: Text("No tienes cupones disponibles."))]
                      : availableCoupons.map((coupon) {
                          // --- CORRECCIÓN AQUÍ ---
                          final String discountDisplay = ((coupon['discount'] as num?)?.toDouble() ?? 0.0 * 100).toStringAsFixed(0);
                          final String couponIdDisplay = _formatCouponIdForDisplay(coupon['id']);
                          // --- FIN DE LA CORRECCIÓN ---

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                            leading: Icon(Icons.local_offer_outlined, size: 20, color: Colors.green[400]),
                            title: Text(coupon['description'] ?? 'Cupón de Descuento'),
                            subtitle: Text("Descuento: $discountDisplay% - ID: $couponIdDisplay"),
                          );
                        }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}