import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/poi_provider.dart';
import '../models/poi.dart';
import '../models/bic.dart';
import '../models/itinerary.dart';

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
              if (_showFog)
                PolygonLayer(
                  polygons: poiProvider.borders.where((muni) {
                    final isDiscovered = poiProvider.discoveredMunicipios.any(
                      (dm) => dm.toUpperCase().trim() == muni.name.toUpperCase().trim()
                    );
                    return !isDiscovered;
                  }).expand((muni) {
                    return muni.paths.map((path) => Polygon(
                      points: path,
                      color: const Color(0xFF001529).withOpacity(0.85),
                      borderStrokeWidth: 0,
                    ));
                  }).toList(),
                ),
              PolylineLayer(
                polylines: [
                  ...poiProvider.borders.expand((b) => b.paths).map((path) => Polyline(
                    points: path,
                    color: Colors.white.withOpacity(0.3),
                    strokeWidth: 1.5,
                  )),
                  // DIBUJO DE SENDEROS (FORZADO)
                  ...poiProvider.itineraries.where((it) => it.paths != null).expand((it) {
                    final isHighlighted = poiProvider.highlightedItineraryId == it.matricula;
                    final color = Color(int.parse(it.difficultyColor.replaceFirst('#', '0xFF')));
                    return it.paths!.map((path) {
                      final coords = path as List;
                      final points = coords.map((p) => LatLng(p[1].toDouble(), p[0].toDouble())).toList();
                      return Polyline(
                        points: points,
                        color: isHighlighted ? Colors.orange : color.withOpacity(0.8),
                        strokeWidth: isHighlighted ? 6.0 : 3.0,
                      );
                    });
                  }),
                ],
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
                  // ESTACIONES METEOROLÓGICAS (NUEVO)
                  ...poiProvider.weatherStations.map((st) => Marker(
                    point: LatLng(st['lat'], st['lng']),
                    width: 40, height: 40,
                    child: GestureDetector(
                      onTap: () => _showWeatherSheet(st),
                      child: _buildMarkerIcon(Icons.thermostat, Colors.blue[900]!),
                    ),
                  )),
                  if (poiProvider.currentPosition != null)
                    Marker(
                      point: LatLng(poiProvider.currentPosition!.latitude, poiProvider.currentPosition!.longitude),
                      width: 40, height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                  // MARCADORES DE INICIO DE SENDEROS (Interactivos)
                  if (poiProvider.showAllTrails)
                    ...poiProvider.itineraries.where((it) => it.startPoint != null).map((it) {
                      final color = Color(int.parse(it.difficultyColor.replaceFirst('#', '0xFF')));
                      return Marker(
                        point: LatLng(it.startPoint![1].toDouble(), it.startPoint![0].toDouble()),
                        width: 45, height: 45,
                        child: GestureDetector(
                          onTap: () => _showItinerarySheet(it, poiProvider),
                          child: _buildMarkerIcon(Icons.directions_walk, color),
                        ),
                      );
                    }),
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
                  const SizedBox(width: 8),
                  _filterChip("Senderos", poiProvider.showAllTrails, (v) => poiProvider.toggleAllTrails(v), Icons.route),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            right: 16,
            child: _buildScoreCard(poiProvider),
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

  void _showWeatherSheet(dynamic st) {
    final provider = Provider.of<POIProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => FutureBuilder<Map<String, dynamic>?>(
        future: provider.fetchStationSensors(st['id']),
        builder: (context, snapshot) {
          final sensors = snapshot.data?['sensors'] as List? ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(st['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                    const Icon(Icons.sensors, color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Municipio: ${st['municipio']}", style: TextStyle(color: Colors.grey[600])),
                const Divider(height: 32),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (sensors.isEmpty)
                  const Text("No hay sensores activos en este momento.")
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("INSTRUMENTOS REALES (Cabildo):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: sensors.map((s) => Chip(
                          avatar: Icon(
                            s['name'].toString().contains("Temperatura") ? Icons.thermostat : Icons.check_circle, 
                            size: 16, color: Colors.green
                          ),
                          label: Text("${s['name']}: ${s['value']} ${s['unit']}"),
                          backgroundColor: Colors.blue[50],
                        )).toList(),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                const Text("Conexión encriptada directa con la Red de Estaciones del Cabildo.", 
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          );
        },
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
              _buildNearbyTrailsSection(poi, provider),
              const SizedBox(height: 20),
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

  void _showItinerarySheet(Itinerary it, POIProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(it.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                Chip(label: Text(it.matricula), backgroundColor: Colors.orange[100]),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Dificultad: ${it.difficulty}", 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(int.parse(it.difficultyColor.replaceFirst('#', '0xFF'))))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(it.isCircular ? Icons.cached : Icons.trending_flat, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(it.isCircular ? "CIRCULAR" : "LINEAL", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.straighten, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text("Distancia: ${it.distancia.toStringAsFixed(0)} m", style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text("INICIAR SEGUIMIENTO DE RUTA"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                provider.setHighlightedItinerary(it.matricula);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Ruta ${it.matricula} activada. ¡Sigue la línea!")),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyTrailsSection(POI poi, POIProvider provider) {
    final nearbyTrails = provider.itineraries.where((it) => 
      poi.enp.isNotEmpty && it.name.contains(poi.enp) || it.municipios.contains(poi.municipio)
    ).toList();

    if (nearbyTrails.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SENDEROS RELACIONADOS", 
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: nearbyTrails.length,
            itemBuilder: (context, index) {
              final it = nearbyTrails[index];
              final color = Color(int.parse(it.difficultyColor.replaceFirst('#', '0xFF')));
              return GestureDetector(
                onTap: () {
                  provider.setHighlightedItinerary(it.matricula);
                  Navigator.pop(context); // Cerramos ficha POI
                  // Volamos al inicio del sendero
                  if (it.startPoint != null) {
                    _mapController.move(LatLng(it.startPoint![1], it.startPoint![0]), 14.0);
                  }
                  // Abrimos la ficha del sendero automáticamente
                  _showItinerarySheet(it, provider);
                },
                child: Card(
                  elevation: 2,
                  color: color.withOpacity(0.1),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.matricula, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                        Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        const Spacer(),
                        Text("${it.distancia.toStringAsFixed(0)}m", style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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