import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/presentation/pages/home_page.dart';
import 'package:proyecto_final/presentation/pages/login_page.dart';
import 'package:proyecto_final/presentation/pages/register_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/pagina.jpg', 
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[800], 
                child: const Center(
                  child: Text(
                    'GameShopX',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            color: Colors.black.withOpacity(0.65),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2), 
                Text(
                  'Bienvenido a GameShopX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36, 
                    fontWeight: FontWeight.bold,
                    shadows: [ 
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    'Tu mercado de juegos de confianza.', 
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(flex: 1),
                _buildAuthButton(
                  context,
                  text: 'Iniciar Sesión',
                  icon: Icons.login,
                  onPressed: () => Get.to(() => LoginPage(), transition: Transition.rightToLeftWithFade),
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                _buildAuthButton(
                  context,
                  text: 'Registrarse',
                  icon: Icons.person_add_alt_1,
                  onPressed: () => Get.to(() => RegisterPage(), transition: Transition.rightToLeftWithFade),
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black87,
                ),
                const Spacer(flex: 3), 
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAuthButton(BuildContext context, {
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(text),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), 
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), 
        ),
        elevation: 5, 
      ),
    );
  }
}
