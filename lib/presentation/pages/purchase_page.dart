import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_final/model/game_listing_model.dart';
import 'package:proyecto_final/controllers/auth_controller.dart';
import 'package:proyecto_final/controllers/notification_controller.dart';
import 'package:proyecto_final/controllers/game_listing_controller.dart';
import 'package:proyecto_final/data/repositories/purchase_history_repository.dart';
import 'package:proyecto_final/presentation/pages/home_page.dart';
import 'package:proyecto_final/model/user_model.dart'; 
import 'package:proyecto_final/data/repositories/user_repository.dart'; 

class PurchasePage extends StatefulWidget {
  final GameListingModel listing;

  const PurchasePage({super.key, required this.listing});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderNameController = TextEditingController();

  final AuthController _authController = Get.find();
  final NotificationController _notificationController = Get.find();
  final GameListingController _gameListingController = Get.find();
  final PurchaseHistoryRepository _purchaseHistoryRepository = Get.find();
  final UserRepository _userRepository = Get.find(); 

  bool _isProcessingPayment = false;

  Map<String, dynamic>? _selectedCouponMap;
  String? _selectedCouponId;
  double _finalPrice = 0.0;
  double _discountAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _finalPrice = widget.listing.price;
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderNameController.dispose();
    super.dispose();
  }

  void _applyCouponById(String? couponId) {
    Map<String, dynamic>? foundCoupon;
    if (couponId != null) {
      try {
        foundCoupon = _authController.availableCoupons.firstWhereOrNull((c) => c['id'] == couponId);
      } catch (e) {
        print("Error buscando cupón por ID: $e");
        foundCoupon = null;
      }
    }

    setState(() {
      _selectedCouponId = couponId;
      _selectedCouponMap = foundCoupon;

      if (_selectedCouponMap != null) {
        double discountPercentage = (_selectedCouponMap!['discount'] as num?)?.toDouble() ?? 0.0;
        _discountAmount = widget.listing.price * discountPercentage;
        _finalPrice = widget.listing.price - _discountAmount;
        if (_finalPrice < 0) _finalPrice = 0;
      } else {
        _discountAmount = 0.0;
        _finalPrice = widget.listing.price;
      }
    });
  }

  Future<void> _simulatePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isProcessingPayment = true; });

    Get.dialog(
      AlertDialog(
        title: const Text('Procesando Pago...'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Por favor, espera un momento.'),
          ],
        ),
      ),
      barrierDismissible: false,
    );
    
    await Future.delayed(const Duration(seconds: 3)); 

    if (Get.isDialogOpen ?? false) {
      Get.back(); 
    }

    final String? buyerId = _authController.currentUserId;
    final String? buyerName = _authController.localUser.value?.username ?? _authController.currentUserName;

    if (buyerId == null || buyerName == null) {
      Get.snackbar(
        "Error", "No se pudo obtener la información del comprador. Intenta iniciar sesión de nuevo.",
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white,
      );
      setState(() { _isProcessingPayment = false; });
      return;
    }

    bool couponUsedSuccessfully = true;
    if (_selectedCouponMap != null) {
      couponUsedSuccessfully = await _authController.useCoupon(_selectedCouponMap!['id']);
      if (!couponUsedSuccessfully) {
        print("[PurchasePage] ADVERTENCIA: No se pudo marcar el cupón como usado.");
      }
    }

    try {
        await _purchaseHistoryRepository.createPurchaseRecord(
        buyerId: buyerId,
        buyerName: buyerName,
        sellerId: widget.listing.sellerId,
        listingId: widget.listing.id,
        listingTitle: widget.listing.title,
        pricePaid: _finalPrice,
        couponIdUsed: _selectedCouponMap?['id'] as String?,
        discountApplied: _discountAmount,
      );
      print("[PurchasePage] Registro de compra creado exitosamente.");
    } catch (e) {
      print("[PurchasePage] Error al crear el registro de compra: $e");
      Get.snackbar("Error", "No se pudo registrar la compra: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      setState(() { _isProcessingPayment = false; });
      return;
    }

    bool statusUpdated = await _gameListingController.updateListingStatus(
        widget.listing.id, 'sold', buyerId); 

    if (!statusUpdated) {
        print("ADVERTENCIA (PurchasePage): No se pudo actualizar el estado del listado a 'vendido'.");
    }
    
    await _notificationController.sendSaleNotificationToSeller(
      sellerId: widget.listing.sellerId,
      buyerId: buyerId,
      buyerName: buyerName,
      listingId: widget.listing.id,
      listingTitle: widget.listing.title,
    );

    await _notificationController.sendPurchaseConfirmationToBuyer(
      buyerId: buyerId,
      listingId: widget.listing.id,
      listingTitle: widget.listing.title,
      sellerId: widget.listing.sellerId,
    );

    Get.snackbar(
      '¡Compra Exitosa!',
      '¡Gracias por tu compra de ${widget.listing.title}! Pagaste: ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(_finalPrice)}',
      snackPosition: SnackPosition.TOP, backgroundColor: Colors.green, colorText: Colors.white,
      duration: const Duration(seconds: 7), margin: const EdgeInsets.all(15), borderRadius: 10,
    );
    
    setState(() { _isProcessingPayment = false; });
    Get.offAll(() => HomePage());
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = widget.listing.getDisplayImageUrl();
    final List<Map<String, dynamic>> availableCoupons = _authController.availableCoupons;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pagar: ${widget.listing.title}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl, 
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print("Error cargando imagen de red en PurchasePage ($imageUrl): $error");
                          return Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey[600]));
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey[600])),
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.listing.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "Precio Original: ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(widget.listing.price)}",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration: _discountAmount > 0 ? TextDecoration.lineThrough : null,
                    color: _discountAmount > 0 ? Colors.grey[500] : Theme.of(context).textTheme.titleMedium?.color,
                  ),
            ),
            if (_discountAmount > 0) ...[
              Text(
                "Descuento: -${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(_discountAmount)}",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green[600]),
              ),
            ],
            Text(
              "Precio Final: ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(_finalPrice)}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const Divider(),

            if (availableCoupons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Aplicar Cupón de Descuento',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Selecciona un cupón',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_offer_outlined, color: Colors.amber[700]),
                ),
                value: _selectedCouponId,
                hint: const Text('Elige un cupón si tienes'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(
                    value: null, 
                    child: Text('No usar cupón'),
                  ),
                  ...availableCoupons.map<DropdownMenuItem<String>>((Map<String, dynamic> coupon) {
                    final String couponId = coupon['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(); 
                    final String discountPercentage = (((coupon['discount'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(0);
                    return DropdownMenuItem<String>(
                      value: couponId,
                      child: Text('${coupon['description'] ?? 'Cupón'} ($discountPercentage%)'),
                    );
                  }).toList(),
                ],
                onChanged: (String? selectedId) {
                  _applyCouponById(selectedId);
                },
              ),
              const SizedBox(height: 12),
              const Divider(),
            ],
            const SizedBox(height: 12),

            Text(
              'Ingresa los Detalles de tu Tarjeta',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _cardHolderNameController,
                    decoration: const InputDecoration(labelText: 'Nombre en la Tarjeta', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                    validator: (value) => value == null || value.isEmpty ? 'Ingresa el nombre del titular' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(labelText: 'Número de Tarjeta', border: OutlineInputBorder(), prefixIcon: Icon(Icons.credit_card)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(19),
                      _CardNumberInputFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa el número de tarjeta';
                      final cleanValue = value.replaceAll(' ', '');
                      if (cleanValue.length < 13 || cleanValue.length > 19) return 'Número de tarjeta inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiryDateController,
                          decoration: const InputDecoration(labelText: 'Vencimiento (MM/AA)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                            _ExpiryDateInputFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa la fecha';
                            if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(value)) return 'Formato MM/AA inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          decoration: const InputDecoration(labelText: 'CVV', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                            obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa el CVV';
                            if (value.length < 3 || value.length > 4) return 'CVV inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: _isProcessingPayment 
                        ? Container(width:24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)) 
                        : const Icon(Icons.payment_rounded),
                    label: Text(_isProcessingPayment 
                        ? 'Procesando...' 
                        : 'Pagar ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(_finalPrice)}'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isProcessingPayment ? null : _simulatePayment,
                  ),
                ],
              )
            ),
            const SizedBox(height: 20),
              Center(
                child: Text(
                  "Nota: Esta es una simulación. No se realizará ningún cargo real.",
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var newText = newValue.text.replaceAll('/', ''); 

    if (newValue.selection.baseOffset == 0 && newValue.text.isEmpty) { 
        return newValue;
    }
    
    var buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      if (i == 1 && newText.length > 1) { 
      }
    }

    var string = buffer.toString();
    if (string.length > 5) {
      string = string.substring(0, 5);
    }
    
    return TextEditingValue(
        text: string,
        selection: TextSelection.collapsed(offset: string.length)
    );
  }
}