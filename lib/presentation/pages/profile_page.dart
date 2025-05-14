// lib/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart'; // Para mostrar info del usuario y logout

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener el AuthController para acceder a la información del usuario y al método de logout
    final AuthController authController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              // Llamar al método de logout del AuthController
              // El AuthController se encargará de la navegación a LoginPage
              await authController.logout();
            },
          ),
        ],
      ),
      body: Obx(() { // Usar Obx para reaccionar a los cambios en authController.appwriteUser
        // Verificar si la información del usuario está disponible
        if (authController.appwriteUser.value == null) {
          // Si no hay información del usuario (debería estar logueado para llegar aquí,
          // pero es una buena práctica verificar), mostrar un indicador o mensaje.
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Cargando información del perfil..."),
              ],
            ),
          );
        }

        // Si la información del usuario está disponible, mostrarla
        final user = authController.appwriteUser.value!;
        return ListView( // Usar ListView para permitir más contenido y scroll si es necesario
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Center(
              child: CircleAvatar(
                radius: 50,
                // Podrías añadir una imagen de perfil aquí si la tuvieras
                // backgroundImage: user.prefs?.data['profileImageUrl'] != null ? NetworkImage(user.prefs!.data['profileImageUrl']) : null,
                child: user.prefs?.data['profileImageUrl'] == null 
                       ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: TextStyle(fontSize: 40)) 
                       : null,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Usuario',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20, thickness: 1),
                    ListTile(
                      leading: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Nombre'),
                      subtitle: Text(user.name.isNotEmpty ? user.name : 'No especificado'),
                    ),
                    ListTile(
                      leading: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Correo Electrónico'),
                      subtitle: Text(user.email),
                    ),
                    ListTile(
                      leading: Icon(Icons.verified_user_outlined, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Estado del Correo'),
                      subtitle: Text(user.emailVerification ? 'Verificado' : 'No Verificado'),
                    ),
                     ListTile(
                      leading: Icon(Icons.date_range_outlined, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Fecha de Registro'),
                      subtitle: Text(user.registration != null ? Get.find<GameListingController>().formatDate(user.registration!) : 'No disponible'), // Necesitarías un método para formatear la fecha
                    ),
                    // Puedes añadir más información aquí, como los puntos del usuario, etc.
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Aquí podrías añadir secciones para "Mis Artículos", "Mis Puntos", "Configuración", etc.
            // Ejemplo:
            // ElevatedButton(
            //   onPressed: () {
            //     // Navegar a la página de "Mis Artículos"
            //   },
            //   child: const Text('Ver Mis Artículos Publicados'),
            // ),
          ],
        );
      }),
    );
  }
}

// Necesitarás añadir un método para formatear la fecha en GameListingController o en una clase de utilidades.
// Por ejemplo, en GameListingController:
// import 'package:intl/intl.dart'; // Añade intl a tu pubspec.yaml
// String formatDate(String dateString) {
//   try {
//     final DateTime dateTime = DateTime.parse(dateString);
//     return DateFormat('dd/MM/yyyy, hh:mma').format(dateTime.toLocal()); // Formato de ejemplo
//   } catch (e) {
//     return dateString; // Devolver el string original si hay error de parseo
//   }
// }
// Y luego en ProfilePage, llamarías a:
// Get.find<GameListingController>().formatDate(user.registration!)
// O mejor, crea una clase de utilidades para esto.
