import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/presentation/pages/home_page.dart';
import 'package:proyecto_final/presentation/pages/login_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    _checkAuth(authController);
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  void _checkAuth(AuthController authController) async {
    await Future.delayed(Duration(seconds: 1));
    final isLoggedIn = await authController.checkAuth();
    if (isLoggedIn) {
      Get.off(() => HomePage());
    } else {
      Get.off(() => LoginPage());
    }
  }
}
