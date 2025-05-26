// lib/presentation/pages/midpoint_map_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// import 'package:url_launcher/url_launcher.dart'; // Para atribuciones si las necesitas

// TU CLAVE DE API DE MAPTILER
const String MAPTILER_API_KEY = "bvPvMjGXGLI6n2cUv6PA";
const String MAPTILER_MAP_STYLE = "streets-v2"; // Puedes cambiar el estilo (ej: basic-v2, outdoor-v2)

class MidpointMapPage extends StatefulWidget {
  final double userALatitude;
  final double userALongitude;
  final String userAName;
  final double userBLatitude;
  final double userBLongitude;
  final String userBName;
  final double midpointLatitude;
  final double midpointLongitude;

  const MidpointMapPage({
    super.key,
    required this.userALatitude,
    required this.userALongitude,
    required this.userAName,
    required this.userBLatitude,
    required this.userBLongitude,
    required this.userBName,
    required this.midpointLatitude,
    required this.midpointLongitude,
  });

  @override
  State<MidpointMapPage> createState() => _MidpointMapPageState();
}

class _MidpointMapPageState extends State<MidpointMapPage> {
  late MapController _mapController; // No necesita Completer con flutter_map
  List<Marker> _markers = [];
  late LatLng _midpointPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _midpointPosition = LatLng(widget.midpointLatitude, widget.midpointLongitude);

    _markers.addAll([
      Marker(
        width: 120.0, // Ancho del widget del marcador
        height: 70.0, // Alto del widget del marcador
        point: LatLng(widget.userALatitude, widget.userALongitude),
        child: _buildMarkerWidget(Icons.person_pin_circle, Colors.green, widget.userAName),
      ),
      Marker(
        width: 120.0,
        height: 70.0,
        point: LatLng(widget.userBLatitude, widget.userBLongitude),
        child: _buildMarkerWidget(Icons.person_pin_circle, Colors.blue, widget.userBName),
      ),
      Marker(
        width: 120.0,
        height: 70.0,
        point: _midpointPosition,
        child: _buildMarkerWidget(Icons.location_on, Colors.purple, "Punto Medio"),
      ),
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Asegurarse que el widget aún está montado
         _fitAllMarkersWithDelay();
      }
    });
  }

  Widget _buildMarkerWidget(IconData icon, Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(icon, color: color, size: 35.0),
      ],
    );
  }
  
  void _fitAllMarkersWithDelay() {
    // Pequeño delay para asegurar que el mapa esté listo
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _mapController != null && _markers.isNotEmpty) {
        _fitAllMarkers();
      }
    });
  }


  void _fitAllMarkers() {
    if (_markers.isEmpty) return;

    List<LatLng> points = _markers.map((m) => m.point).toList();
    if (points.isEmpty) return;

    // Crear un LatLngBounds a partir de los puntos
    LatLngBounds bounds = LatLngBounds.fromPoints(points);

    // Si todos los puntos son idénticos, LatLngBounds puede no funcionar bien.
    // En ese caso, simplemente centrar en ese punto con un zoom razonable.
    bool allSamePoint = points.every((p) => p.latitude == points.first.latitude && p.longitude == points.first.longitude);

    if (allSamePoint) {
        _mapController.move(points.first, 15.0); // Zoom más cercano para un solo punto
    } else {
        _mapController.fitCamera(
            CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(70.0), // Aumentar padding si es necesario
            )
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MAPTILER_API_KEY == "TU_MAPTILER_API_KEY_AQUI" || MAPTILER_API_KEY.isEmpty) {
        return Scaffold(
            appBar: AppBar(title: const Text('Configuración Requerida')),
            body: const Center(
                child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                        "Por favor, añade tu API Key de MapTiler en midpoint_map_page.dart para ver el mapa.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                ),
            ),
        );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Encuentro Sugerido'),
        actions: [
            IconButton(
                icon: const Icon(Icons.zoom_out_map),
                tooltip: "Ajustar Zoom",
                onPressed: _fitAllMarkers,
            )
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _midpointPosition,
          initialZoom: 6, // Se ajustará con fitCamera
          // onTap: (tapPosition, point) => _fitAllMarkers(), // Opcional: Re-ajustar al tocar el mapa
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://api.maptiler.com/maps/$MAPTILER_MAP_STYLE/{z}/{x}/{y}.png?key=$MAPTILER_API_KEY',
            userAgentPackageName: 'com.tuempresa.proyecto_final', // CAMBIA ESTO a tu package name real
            // Opcional: Atribuciones (Requerido por MapTiler y OpenStreetMap)
            // RichAttributionWidget(
            //   attributions: [
            //     TextSourceAttribution(
            //       'MapTiler',
            //       onTap: () => launchUrl(Uri.parse('https://www.maptiler.com/copyright/')),
            //     ),
            //     TextSourceAttribution(
            //       'OpenStreetMap contributors',
            //       onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
            //     ),
            //   ],
            // ),
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}