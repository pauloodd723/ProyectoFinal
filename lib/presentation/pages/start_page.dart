import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          ),
          Container(
            color: Colors.black.withOpacity(0.6),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to GameShopX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Get.to(() => LoginPage()),
                child: Text('Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.to(() => RegisterPage()),
                child: Text('Register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
