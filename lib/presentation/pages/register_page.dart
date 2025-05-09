import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';

class RegisterPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  RegisterPage({super.key});

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
                        controller: _usernameController,
                        decoration: InputDecoration(labelText: 'Nombre de usuario'),
                        validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                      ),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: 'Correo'),
                        validator: (value) {
                          if (value!.isEmpty) return 'Campo requerido';
                          if (!GetUtils.isEmail(value)) return 'Correo inválido';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: 'Contraseña'),
                        obscureText: true,
                        validator: (value) {
                          if (value!.isEmpty) return 'Campo requerido';
                          if (value.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      Obx(() => authController.isLoading.value
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  authController.register(
                                    _emailController.text,
                                    _passwordController.text,
                                    _usernameController.text,
                                  );
                                }
                              },
                              child: Text('Registrarse'),
                            )),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('¿Ya tienes cuenta? Inicia sesión'),
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
