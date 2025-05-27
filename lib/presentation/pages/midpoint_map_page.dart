import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const String MAPTILER_API_KEY = "bvPvMjGXGLI6n2cUv6PA";
const String MAPTILER_MAP_STYLE = "streets-v2"; 

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
  late MapController _mapController;
  List<Marker> _markers = [];
  late LatLng _midpointPosition;
  final List<LatLng> _routePoints = []; 

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _midpointPosition = LatLng(widget.midpointLatitude, widget.midpointLongitude);

    final userAPosition = LatLng(widget.userALatitude, widget.userALongitude);
    final userBPosition = LatLng(widget.userBLatitude, widget.userBLongitude);

    _markers.addAll([
      Marker(
        width: 120.0,
        height: 70.0,
        point: userAPosition,
        child: _buildMarkerWidget(Icons.person_pin_circle_rounded, Colors.green, widget.userAName),
      ),
      Marker(
        width: 120.0,
        height: 70.0,
        point: userBPosition,
        child: _buildMarkerWidget(Icons.person_pin_circle_rounded, Colors.blue, widget.userBName),
      ),
      Marker(
        width: 120.0,
        height: 70.0,
        point: _midpointPosition,
        child: _buildMarkerWidget(Icons.location_on_rounded, Colors.purple, "Punto Medio"),
      ),
    ]);

    _routePoints.addAll([userAPosition, userBPosition]);


    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
         _fitAllMarkersWithDelay();
      }
    });
  }

  Widget _buildMarkerWidget(IconData icon, Color color, String label) {
    return Tooltip(
      message: label,
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0,1))
              ]
            ),
            child: Text(
              label, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Icon(icon, color: color, size: 35.0, shadows: const [Shadow(color: Colors.black38, blurRadius: 3)]),
        ],
      ),
    );
  }
  
  void _fitAllMarkersWithDelay() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _markers.isNotEmpty) {
        _fitAllMarkers();
      }
    });
  }

  void _fitAllMarkers() {
    if (_markers.isEmpty) return;

    List<LatLng> points = _markers.map((m) => m.point).toList();
    if (points.isEmpty) return;
    
    LatLngBounds bounds = LatLngBounds.fromPoints(points);

    bool allSamePoint = points.length > 1 && points.every((p) => p.latitude == points.first.latitude && p.longitude == points.first.longitude);

    if (allSamePoint || points.length == 1) {
        _mapController.move(points.first, 13.0); 
    } else {
        _mapController.fitCamera(
            CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(70.0), 
            )
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MAPTILER_API_KEY == "TU_MAPTILER_API_KEY_AQUI" || MAPTILER_API_KEY.isEmpty || MAPTILER_API_KEY == "bvPvMjGXGLI6n2cUv6PA" && MAPTILER_API_KEY.length < 10) { // Placeholder check
        return Scaffold(
            appBar: AppBar(title: const Text('Configuración Requerida')),
            body: const Center(
                child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                        "Por favor, verifica tu API Key de MapTiler en midpoint_map_page.dart para ver el mapa.",
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
                icon: const Icon(Icons.zoom_out_map_rounded),
                tooltip: "Ajustar Zoom",
                onPressed: _fitAllMarkers,
            )
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _midpointPosition,
          initialZoom: 6,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://api.maptiler.com/maps/$MAPTILER_MAP_STYLE/{z}/{x}/{y}.png?key=$MAPTILER_API_KEY',
            userAgentPackageName: 'com.tuempresa.proyecto_final', 
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}