// lib/presentation/pages/user_activity_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/controllers/user_controller.dart';
import 'package:proyecto_final/model/purchase_history_model.dart';

class UserActivityPage extends StatefulWidget {
  const UserActivityPage({super.key});

  @override
  State<UserActivityPage> createState() => _UserActivityPageState();
}

class _UserActivityPageState extends State<UserActivityPage> with SingleTickerProviderStateMixin {
  final UserController _userController = Get.find();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Cargar la actividad del usuario cuando se inicializa la página
    _userController.loadUserActivity();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _refreshData() async {
    await _userController.loadUserActivity();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Actividad'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Comprados'),
            Tab(icon: Icon(Icons.storefront_outlined), text: 'Vendidos'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPurchasedGamesList(context),
            _buildSoldGamesList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasedGamesList(BuildContext context) {
    return Obx(() {
      if (_userController.isLoadingPurchasedGames.value && _userController.purchasedGames.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_userController.purchasedGamesError.value.isNotEmpty) {
        return Center(child: Text('Error: ${_userController.purchasedGamesError.value}'));
      }
      if (_userController.purchasedGames.isEmpty) {
        return const Center(child: Text('Aún no has comprado ningún juego.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _userController.purchasedGames.length,
        itemBuilder: (context, index) {
          final PurchaseHistoryModel purchase = _userController.purchasedGames[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined, size: 36),
              title: Text(purchase.listingTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Comprado el: ${DateFormat('dd/MM/yyyy, hh:mm a', 'es_CO').format(purchase.purchaseDate.toLocal())}\n'
                  'Precio: ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(purchase.pricePaid)}'
              ),
              isThreeLine: true,
              // Puedes añadir más detalles o un onTap si es necesario
            ),
          );
        },
      );
    });
  }

  Widget _buildSoldGamesList(BuildContext context) {
    return Obx(() {
      if (_userController.isLoadingSoldGames.value && _userController.soldGames.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_userController.soldGamesError.value.isNotEmpty) {
        return Center(child: Text('Error: ${_userController.soldGamesError.value}'));
      }
      if (_userController.soldGames.isEmpty) {
        return const Center(child: Text('Aún no has vendido ningún juego.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _userController.soldGames.length,
        itemBuilder: (context, index) {
          final PurchaseHistoryModel sale = _userController.soldGames[index];
          return Card(
             margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: ListTile(
              leading: const Icon(Icons.monetization_on_outlined, size: 36),
              title: Text(sale.listingTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Vendido a: ${sale.buyerName}\n'
                  'Fecha: ${DateFormat('dd/MM/yyyy, hh:mm a', 'es_CO').format(sale.purchaseDate.toLocal())}\n'
                  'Precio: ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(sale.pricePaid)}'
              ),
              isThreeLine: true,
              // Puedes añadir más detalles o un onTap si es necesario
            ),
          );
        },
      );
    });
  }
}