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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/register.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Register GameShopX',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 30),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(_usernameController, 'Nombre de usuario'),
                          SizedBox(height: 16),
                          _buildTextField(_emailController, 'Correo'),
                          SizedBox(height: 16),
                          _buildTextField(_passwordController, 'Contraseña', obscure: true),
                          SizedBox(height: 20),
                          Obx(() => authController.isLoading.value
                              ? CircularProgressIndicator()
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    foregroundColor: Colors.white,
                                  ),
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
                            child: Text('¿Ya tienes cuenta? Inicia sesión', style: TextStyle(color: Colors.white)),
                          ),
                          Obx(() => authController.error.value.isNotEmpty
                              ? Text(authController.error.value, style: TextStyle(color: Colors.red))
                              : SizedBox.shrink()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      ),
      validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
    );
  }
}
