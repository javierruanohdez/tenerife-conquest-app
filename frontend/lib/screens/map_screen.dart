import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/poi_provider.dart';
import '../models/poi.dart';
import '../models/bic.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _showBICs = true;
  bool _showNature = true;
  bool _showFog = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<POIProvider>(context, listen: false).loadData();
      _determinePosition();
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Geolocator.getPositionStream().listen((Position position) {
      Provider.of<POIProvider>(context, listen: false).updateLocation(position);
    });
  }

  @override
  Widget build(BuildContext context) {
    final poiProvider = Provider.of<POIProvider>(context);
    
    // CAPA DE NIEBLA: Polígonos de municipios conquistados
    List<List<LatLng>> holes = [];
    try {
      for (var border in poiProvider.borders) {
        if (poiProvider.discoveredMunicipios.contains(border.name)) {
          for (var path in border.paths) {
            if (path.isNotEmpty) holes.add(path);
          }
        }
      }
    } catch (e) {
      print("[MAP ERROR] Error calculando huecos de niebla: $e");
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Tenerife Quest", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white.withOpacity(0.8),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        automaticallyImplyLeading: false, 
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(28.2916, -16.6291),
              initialZoom: 10.0,
              minZoom: 9.0, 
              maxZoom: 18.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(27.7, -17.2),
                  const LatLng(28.9, -15.8),
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.tnf_datos_app',
              ),
              // LA NUEVA CAPA DE NIEBLA (SOLO EN TIERRA FIRME)
              if (_showFog)
                PolygonLayer(
                  polygons: poiProvider.borders.where((muni) => !poiProvider.discoveredMunicipios.contains(muni.name)).expand((muni) {
                    return muni.paths.map((path) => Polygon(
                      points: path,
                      color: const Color(0xFF001529).withOpacity(0.85),
                      borderStrokeWidth: 0,
                    ));
                  }).toList(),
                ),
              PolylineLayer(
                polylines: poiProvider.borders.expand((b) => b.paths).map((path) => Polyline(
                  points: path,
                  color: Colors.white.withOpacity(0.3),
                  strokeWidth: 1.5,
                )).toList(),
              ),
              MarkerLayer(
                markers: [
                  if (_showNature)
                    ...poiProvider.pois.map((poi) => Marker(
                      point: LatLng(poi.lat, poi.lng),
                      width: 45, height: 45,
                      child: GestureDetector(
                        onTap: () => _showPOISheet(poi, poiProvider),
                        child: _buildMarkerIcon(Icons.nature_people, Colors.green[700]!),
                      ),
                    )),
                  if (_showBICs)
                    ...poiProvider.bics.map((bic) => Marker(
                      point: LatLng(bic.lat, bic.lng),
                      width: 45, height: 45,
                      child: GestureDetector(
                        onTap: () => _showBICSheet(bic),
                        child: _buildMarkerIcon(Icons.account_balance, Colors.amber[800]!),
                      ),
                    )),
                  if (poiProvider.currentPosition != null)
                    Marker(
                      point: LatLng(poiProvider.currentPosition!.latitude, poiProvider.currentPosition!.longitude),
                      width: 40, height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                ],
              ),
            ],
          ),
          
          if (poiProvider.currentPosition != null)
            _buildSafetyBanner(poiProvider),

          Positioned(
            top: 110,
            left: 0, right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _filterChip("Ver Niebla", _showFog, (v) => setState(() => _showFog = v), Icons.cloud),
                  const SizedBox(width: 8),
                  _filterChip("Naturaleza", _showNature, (v) => setState(() => _showNature = v), Icons.forest),
                  const SizedBox(width: 8),
                  _filterChip("Cultura (BIC)", _showBICs, (v) => setState(() => _showBICs = v), Icons.account_balance),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            right: 16,
            child: _buildScoreCard(poiProvider),
          ),

          if (poiProvider.selectedItinerary != null)
            Positioned(
              top: 160, left: 16, right: 16,
              child: _buildActiveRouteCard(poiProvider),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton(
          onPressed: () {
            if (poiProvider.currentPosition != null) {
              final lat = poiProvider.currentPosition!.latitude;
              final lng = poiProvider.currentPosition!.longitude;
              if (lat > 27.7 && lat < 28.9 && lng > -17.2 && lng < -15.8) {
                _mapController.move(LatLng(lat, lng), 14.0);
                return;
              }
            }
            _mapController.rotate(0);
            _mapController.move(const LatLng(28.2916, -16.6291), 10.0);
          },
          backgroundColor: Colors.white,
          child: const Icon(Icons.my_location, color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildSafetyBanner(POIProvider provider) {
    String? currentMuni;
    try {
      currentMuni = provider.allPois.firstWhere((p) => 
        Geolocator.distanceBetween(provider.currentPosition!.latitude, provider.currentPosition!.longitude, p.lat, p.lng) < 5000
      ).municipio;
    } catch (e) { currentMuni = null; }

    if (currentMuni != null && provider.activeAlerts.containsKey(currentMuni)) {
      return Positioned(
        top: 90, left: 20, right: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red[700],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "PELIGRO EN ${currentMuni.toUpperCase()}: ${provider.activeAlerts[currentMuni]}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _filterChip(String label, bool selected, Function(bool) onSelected, IconData icon) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: Icon(icon, size: 18, color: selected ? Colors.white : Colors.green),
      backgroundColor: Colors.white.withOpacity(0.9),
      selectedColor: Colors.green,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
    );
  }

  Widget _buildMarkerIcon(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
        border: Border.all(color: color, width: 3),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildScoreCard(POIProvider provider) {
    return Card(
      color: Colors.green[800],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.eco, color: Colors.lightGreenAccent),
            const SizedBox(width: 8),
            Text("${provider.points} Eco-Puntos", 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRouteCard(POIProvider provider) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.route, color: Colors.white)),
        title: Text(provider.selectedItinerary!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${provider.selectedItinerary!.matricula} • ${provider.selectedItinerary!.distancia}m"),
        trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => provider.setFilter("Todos")),
      ),
    );
  }

  void _showPOISheet(POI poi, POIProvider provider) {
    double? dist;
    if (provider.currentPosition != null) {
      dist = Geolocator.distanceBetween(provider.currentPosition!.latitude, provider.currentPosition!.longitude, poi.lat, poi.lng);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(poi.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                  Text(poi.municipio.toUpperCase(), style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Text(poi.type, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              if (dist != null) Text("A ${ (dist/1000).toStringAsFixed(1) } km de ti", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const Divider(height: 30),
              const Text("Información", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(poi.description, style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("REGISTRAR VISITA (CHECK-IN)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: (dist != null && dist < 500) ? () {
                  provider.checkIn(poi);
                  Navigator.pop(context);
                } : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.report_problem, color: Colors.orange),
                label: const Text("REPORTAR INCIDENCIA"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showReportDialog(context, poi, provider);
                },
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.bug_report),
                label: const Text("Simular Visita (Demo)"),
                onPressed: () {
                  provider.forceCheckIn(poi);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBICSheet(BIC bic) {
    final provider = Provider.of<POIProvider>(context, listen: false);
    double? dist;
    if (provider.currentPosition != null) {
      dist = Geolocator.distanceBetween(provider.currentPosition!.latitude, provider.currentPosition!.longitude, bic.lat, bic.lng);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(bic.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFB45309)))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(20)),
                    child: const Text("BIC", style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(bic.category, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              if (dist != null) Text("A ${ (dist/1000).toStringAsFixed(1) } km de ti", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
              const Divider(height: 30),
              const Text("Información Histórica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(bic.description, style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("REGISTRAR VISITA (CHECK-IN)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: (dist != null && dist < 500) ? () {
                  provider.checkIn(bic);
                  Navigator.pop(context);
                } : null,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.bug_report),
                label: const Text("Simular Visita (Demo)"),
                onPressed: () {
                  provider.forceCheckIn(bic);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, POI poi, POIProvider provider) {
    String selectedIssue = "Limpieza / Basura";
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Vigilante del Entorno"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ayuda al Cabildo a mantener la isla. ¿Qué has detectado?"),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedIssue,
              items: ["Limpieza / Basura", "Señalización Rota", "Sendero Peligroso", "Exceso de Aforo"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => selectedIssue = v!,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Tipo de incidencia"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Comentario (opcional)"),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.sendReport(poi.id, selectedIssue, commentController.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("¡Reporte enviado! +50 Eco-Puntos."),
                  backgroundColor: Colors.green,
                ));
              }
            },
            child: const Text("Enviar Reporte"),
          ),
        ],
      ),
    );
  }
}
