import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
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

  void _moveTo(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 14.0);
  }

  Color _getSaturationColor(String saturation) {
    switch (saturation) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.red;
      default: return Colors.blue;
    }
  }

  List<LatLng> _generateCirclePoints(LatLng center, double radiusInMeters) {
    List<LatLng> points = [];
    const int numPoints = 20;
    for (int i = 0; i < numPoints; i++) {
      double angle = (i * 2 * math.pi) / numPoints;
      // Rough approximation for meters to lat/lng
      double lat = center.latitude + (radiusInMeters / 111320.0) * math.cos(angle);
      double lng = center.longitude + (radiusInMeters / (111320.0 * math.cos(center.latitude * math.pi / 180))) * math.sin(angle);
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final poiProvider = Provider.of<POIProvider>(context);
    
    // Create holes for discovered areas
    List<List<LatLng>> holes = [];
    for (int id in poiProvider.discoveredPoiIds) {
      final p = poiProvider.allPois.firstWhere((element) => element.id == id);
      holes.add(_generateCirclePoints(LatLng(p.lat, p.lng), 1500)); // 1.5km discovery radius
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Tenerife Eco-Rutas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white.withOpacity(0.8),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      drawer: _buildModernDrawer(poiProvider),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(28.2916, -16.6291),
              initialZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.tnf_datos_app',
              ),
              // THE FOG LAYER
              if (_showFog)
                PolygonLayer(
                  polygons: <Polygon<Object>>[
                    Polygon(
                      points: [
                        const LatLng(29.0, -17.5),
                        const LatLng(29.0, -15.5),
                        const LatLng(27.5, -15.5),
                        const LatLng(27.5, -17.5),
                      ],
                      holePointsList: holes,
                      color: Colors.grey.withOpacity(0.9),
                      borderStrokeWidth: 0,
                    ),
                  ],
                ),
              PolylineLayer(
                polylines: poiProvider.borders.map((border) => Polyline(
                  points: border,
                  color: Colors.black26,
                  strokeWidth: 1.0,
                )).toList(),
              ),
              MarkerLayer(
                markers: [
                  if (poiProvider.currentPosition != null)
                    Marker(
                      point: LatLng(poiProvider.currentPosition!.latitude, poiProvider.currentPosition!.longitude),
                      width: 40, height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                  if (_showNature)
                    ...poiProvider.pois.map((poi) => Marker(
                      point: LatLng(poi.lat, poi.lng),
                      width: 45, height: 45,
                      child: Semantics(
                        label: "Punto de interés: ${poi.name}. Saturación: ${poi.saturation}. ${poiProvider.discoveredPoiIds.contains(poi.id) ? 'Descubierto' : 'Oculto'}",
                        button: true,
                        onTapHint: "Ver detalles de ${poi.name}",
                        child: GestureDetector(
                          onTap: () => _showPOISheet(poi, poiProvider),
                          child: _buildMarkerIcon(Icons.nature_people, _getSaturationColor(poi.saturation)),
                        ),
                      ),
                    )),
                ],
              ),
            ],
          ),
          
          Positioned(
            top: 110,
            left: 0, right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(
                label: "Filtros del mapa",
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
          ),

          Positioned(
            bottom: 30,
            right: 16,
            child: Semantics(
              label: "Tu puntuación eco",
              child: _buildScoreCard(poiProvider),
            ),
          ),

          if (poiProvider.selectedItinerary != null)
            Positioned(
              top: 160, left: 16, right: 16,
              child: _buildActiveRouteCard(poiProvider),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => poiProvider.loadData(),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, Function(bool) onSelected, IconData icon) {
    return Semantics(
      selected: selected,
      label: "Filtro: $label",
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : Colors.green, semanticLabel: ""),
        backgroundColor: Colors.white.withOpacity(0.9),
        selectedColor: Colors.green,
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
      ),
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

  Widget _buildModernDrawer(POIProvider provider) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2E7D32)),
            accountName: const Text("Explorador de Tenerife", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: Text("Nivel: ${provider.points > 500 ? 'Guardián de la Isla' : 'Eco-Viajero'}"),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.green)),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const ListTile(title: Text("FILTRAR POR ZONA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                ...["Todos", "Parque Nacional del Teide", "Parque Rural de Anaga", "Corona Forestal"].map((e) => ListTile(
                  title: Text(e),
                  leading: const Icon(Icons.map_outlined),
                  selected: provider.selectedEspacio == e,
                  onTap: () {
                    provider.setFilter(e);
                    final p = provider.getFirstPoiInEspacio(e);
                    if (p != null) _moveTo(p.lat, p.lng);
                    Navigator.pop(context);
                  },
                )),
                const Divider(),
                const ListTile(title: Text("BIC CERCANOS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                ...provider.bics.take(5).map((bic) => ListTile(
                  title: Text(bic.name),
                  subtitle: Text(bic.category),
                  leading: const Icon(Icons.account_balance, color: Colors.amber),
                  onTap: () {
                    Navigator.pop(context);
                    _showBICSheet(bic);
                  },
                )),
              ],
            ),
          ),
        ],
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
                  Semantics(
                    label: "Nivel de saturación: ${poi.saturation}",
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: _getSaturationColor(poi.saturation).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(poi.saturation.toUpperCase(), style: TextStyle(color: _getSaturationColor(poi.saturation), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(poi.type, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              if (dist != null) 
                Semantics(
                  label: "Distancia: ${ (dist/1000).toStringAsFixed(1) } kilómetros",
                  child: Text("A ${ (dist/1000).toStringAsFixed(1) } km de ti", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ),
              const Divider(height: 30),
              const Text("Información", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(poi.description, style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 30),
              Semantics(
                label: "Confirmar visita para ganar puntos",
                enabled: (dist != null && dist < 500),
                child: ElevatedButton.icon(
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Eco-Puntos sumados! Has desbloqueado esta zona.")));
                  } : null,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: "Reportar incidencia en este lugar",
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.report_problem, color: Colors.orange),
                  label: const Text("REPORTAR INCIDENCIA (Ciencia Ciudadana)"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showReportDialog(context, poi, provider);
                  },
                ),
              ),
              const SizedBox(height: 10),
              // BOTÓN PARA DEMO
              TextButton.icon(
                icon: const Icon(Icons.bug_report),
                label: const Text("Simular Visita (Desbloquear para demo)"),
                onPressed: () {
                  provider.forceCheckIn(poi);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Zona desbloqueada por simulación!")));
                },
              ),
              if (dist != null && dist >= 500)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(child: Text("Debes estar a menos de 500m", style: TextStyle(color: Colors.red, fontSize: 12))),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBICSheet(BIC bic) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(bic.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
            const SizedBox(height: 8),
            Chip(label: Text(bic.category), backgroundColor: Colors.amber[100]),
            const SizedBox(height: 16),
            Text(bic.description, style: const TextStyle(fontSize: 16, height: 1.4)),
            const SizedBox(height: 24),
            Text("Municipio: ${bic.municipio}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
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
                  content: Text("¡Reporte enviado! +50 Eco-Puntos por tu colaboración ciudadana."),
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
