import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/presentation/pages/register_page.dart';

class LoginPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset('assets/images/logo.png', height: 120),
                SizedBox(height: 10),
                Text('GameShop', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: 'Correo'),
                        validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: 'Contraseña'),
                        obscureText: true,
                        validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                      ),
                      SizedBox(height: 20),
                      Obx(() => authController.isLoading.value
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  authController.login(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                                }
                              },
                              child: Text('Iniciar sesión'),
                            )),
                      TextButton(
                        onPressed: () => Get.to(() => RegisterPage()),
                        child: Text('¿No tienes cuenta? Regístrate'),
                      ),
                      Obx(() => authController.error.value.isNotEmpty
                          ? Text(authController.error.value, style: TextStyle(color: Colors.red))
                          : SizedBox.shrink()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
