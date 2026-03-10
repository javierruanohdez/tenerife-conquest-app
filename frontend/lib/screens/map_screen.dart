import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'ranking_screen.dart';
import '../providers/poi_provider.dart';
import '../models/poi.dart';
import '../models/bic.dart';
import '../models/itinerary.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _showBICs = true;
  bool _showNature = true;
  bool _showFog = true;
  bool _showWeather = true;

  bool _guayotaAlertShown = false; // Flag para controlar si la alerta ya se mostró en esta sesión

  // Tutorial Keys
  final GlobalKey _rankingKey = GlobalKey();
  final GlobalKey _scoreKey = GlobalKey();
  final GlobalKey _filtersKey = GlobalKey();
  late TutorialCoachMark tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<POIProvider>(context, listen: false).loadData();
      _determinePosition();
      
      final prefs = await SharedPreferences.getInstance();
      bool tutorialShown = prefs.getBool('map_tutorial_shown') ?? false;
      if (!tutorialShown) {
        _showTutorial();
        await prefs.setBool('map_tutorial_shown', true);
      }
    });
  }

  void _showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.black,
      textSkip: "SALTAR",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        print("Tutorial finalizado");
      },
      onClickTarget: (target) {
        print("Click en target: $target");
      },
      onSkip: () {
        print("Tutorial saltado");
        return true;
      },
    )..show(context: context);
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];

    targets.add(
      TargetFocus(
        identify: "ranking",
        keyTarget: _rankingKey,
        alignSkip: Alignment.bottomRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Ranking y Grupos",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Pulsa aquí para ver cómo vas respecto a otros exploradores y unirte a grupos.",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "filters",
        keyTarget: _filtersKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Filtros del Mapa",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Personaliza tu vista. Puedes ocultar la niebla, ver estaciones meteorológicas o senderos.",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "score",
        keyTarget: _scoreKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Tu Progreso",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Aquí puedes ver tus puntos totales acumulados explorando la isla.",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    return targets;
  }

  void _showGuayotaAlertDialog(String message) {
    if (_guayotaAlertShown) return; // Si ya se mostró, no la mostramos de nuevo
    _guayotaAlertShown = true;

    showDialog(
      context: context,
      barrierDismissible: false, // El usuario debe interactuar con el diálogo
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF5E6), // Color pergamino
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: Colors.brown, width: 3)),
        title: Center(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15), // Bordes redondeados para la imagen
                child: Image.asset('assets/guayota.png', width: 120, height: 120, fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
              const Text("¡LA IRA DE GUAYOTA HA DESPERTADO!", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ),
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.brown, fontSize: 15)),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10)),
              onPressed: () => Navigator.pop(context),
              child: const Text("PROCEDER CON CAUTELA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
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
    final hasActiveAlerts = poiProvider.activeAlerts.isNotEmpty;

    // Mostrar el modal si hay alertas activas y no se ha mostrado aún
    if (hasActiveAlerts && !_guayotaAlertShown) {
      final firstMuniAlert = poiProvider.activeAlerts.values.first;
      if (firstMuniAlert.contains("GUAYOTA")) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showGuayotaAlertDialog("Un intenso calor azota la zona de ${poiProvider.activeAlerts.keys.first}. Los espíritus del volcán están inquietos. Procede con extrema precaución.");
        });
      }
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // if (hasActiveAlerts && poiProvider.activeAlerts.values.first.contains("GUAYOTA")) 
            //   Image.asset('assets/guayota.png', width: 28, height: 28),
            // const SizedBox(width: 8),
            Text("Conquista Tenerife", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
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
              minZoom: 3.0, 
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.tnf_datos_app',
              ),
              if (_showFog && poiProvider.borders.isNotEmpty)
                PolygonLayer(
                  polygons: poiProvider.borders.map((muni) {
                    final name = muni.name.toUpperCase().trim();
                    final isDanger = poiProvider.isGuayotaZone(name);
                    final opacity = poiProvider.getMuniOpacity(name);
                    
                    // La opacidad disminuye (se aclara) gradualmente según el número de visitas
                    Color polygonColor = const Color(0xFF001529).withOpacity(opacity);
                    if (isDanger) {
                      polygonColor = Colors.orange.withOpacity(0.5);
                    }

                    return muni.paths.map((path) => Polygon(
                      points: path,
                      color: polygonColor,
                      borderStrokeWidth: isDanger ? 3 : 0,
                      borderColor: isDanger ? Colors.red : Colors.transparent,
                    ));
                  }).expand((i) => i).toList(),
                ),
              PolylineLayer(
                polylines: [
                  ...poiProvider.borders.expand((b) => b.paths).map((path) => Polyline(
                    points: path,
                    color: Colors.white.withOpacity(0.3),
                    strokeWidth: 1.0,
                  )),
                  ...poiProvider.itineraries.where((it) => it.paths != null).expand((it) {
                    final isHighlighted = poiProvider.highlightedItineraryId == it.matricula;
                    final colorStr = it.difficultyColor.startsWith('#') ? it.difficultyColor.replaceFirst('#', '0xFF') : '0xFFFF9800';
                    final color = Color(int.tryParse(colorStr) ?? 0xFFFF9800);
                    return it.paths!.map((path) {
                      try {
                        final coords = path as List;
                        final points = coords.map((p) => LatLng(p[1].toDouble(), p[0].toDouble())).toList();
                        return Polyline(
                          points: points,
                          color: isHighlighted ? Colors.orange : color.withOpacity(0.6),
                          strokeWidth: isHighlighted ? 6.0 : 3.0,
                        );
                      } catch (e) { return Polyline(points: [], color: Colors.transparent); }
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
                        onTap: () => _showBICSheet(bic, poiProvider),
                        child: _buildMarkerIcon(Icons.account_balance, Colors.amber[800]!),
                      ),
                    )),
                  if (_showWeather)
                    ...poiProvider.weatherStations.map((st) => Marker(
                      point: LatLng((st['lat'] as num).toDouble(), (st['lng'] as num).toDouble()),
                      width: 35, height: 35,
                      child: GestureDetector(
                        onTap: () => _showWeatherSheet(st),
                        child: _buildMarkerIcon(Icons.thermostat, Colors.blue[800]!),
                      ),
                    )),
                  if (poiProvider.showAllTrails)
                    ...poiProvider.itineraries.where((it) => it.startPoint != null).map((it) {
                      final colorStr = it.difficultyColor.replaceFirst('#', '0xFF');
                      final color = Color(int.tryParse(colorStr) ?? 0xFFFFA000);
                      return Marker(
                        point: LatLng(it.startPoint![1].toDouble(), it.startPoint![0].toDouble()),
                        width: 45, height: 45,
                        child: GestureDetector(
                          onTap: () => _showItinerarySheet(it, poiProvider),
                          child: _buildMarkerIcon(Icons.directions_walk, color),
                        ),
                      );
                    }),
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
          
                              // BANNER DE SEGURIDAD (GUAYOTA) - ELIMINADO PARA SUSTITUIR POR MODAL
                              // if (poiProvider.currentPosition != null)
                              //   Positioned(
                              //     top: 70, // Ajustado para estar justo debajo del AppBar que tiene 60 de altura aprox
                              //     left: 20, right: 20,
                              //     child: _buildSafetyBanner(poiProvider),
                              //   ),
                    
                              // BOTÓN DE GRUPOS (ESTILO INSTAGRAM MD)
                              Positioned(
                                top: 50, // Permanece alto a la derecha
                                right: 16,
                                child: GestureDetector(
                                  key: _rankingKey,
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RankingScreen()));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                                    ),
                                    child: const Icon(Icons.send_rounded, color: Colors.black87, size: 28), // Icono similar al de MD de Instagram
                                  ),
                                ),
                              ),
                              
                              Positioned(
                                top: 110, // Los filtros vuelven a su posición alta
                                left: 0, right: 0,
                                child: SingleChildScrollView(
                                  key: _filtersKey,
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      _filterChip("Niebla", _showFog, (v) => setState(() => _showFog = v), Icons.cloud),
                                      const SizedBox(width: 8),
                                      _filterChip("Meteorología", _showWeather, (v) => setState(() => _showWeather = v), Icons.thermostat),
                                      const SizedBox(width: 8),
                                      _filterChip("Naturaleza", _showNature, (v) => setState(() => _showNature = v), Icons.forest),
                                      const SizedBox(width: 8),
                                      _filterChip("Cultura", _showBICs, (v) => setState(() => _showBICs = v), Icons.account_balance),
                                      const SizedBox(width: 8),
                                      _filterChip("Senderos", poiProvider.showAllTrails, (v) => poiProvider.toggleAllTrails(v), Icons.route),
                                    ],
                                  ),
                                ),
                              ),          Positioned(bottom: 30, left: 16, child: Container(key: _scoreKey, child: _buildScoreCard(poiProvider))),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'recenter_btn',
              mini: true,
              onPressed: () {
                if (poiProvider.currentPosition != null) {
                  _mapController.move(LatLng(poiProvider.currentPosition!.latitude, poiProvider.currentPosition!.longitude), 14.0);
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, Function(bool) onSelected, IconData icon) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.black87)),
      selected: selected,
      onSelected: onSelected,
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : Colors.green),
      backgroundColor: Colors.white.withOpacity(0.9),
      selectedColor: Colors.green,
    );
  }

  Widget _buildMarkerIcon(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))], border: Border.all(color: color, width: 2)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildScoreCard(POIProvider provider) {
    return Card(
      color: Colors.green[800],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.eco, color: Colors.lightGreenAccent, size: 20),
            const SizedBox(width: 8),
            Text("${provider.points} pts", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showArtifactDialog(Artifact artifact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF5E6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.brown, width: 2)),
        title: const Center(child: Text("¡HALLAZGO ANCESTRAL!", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: artifact.color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(artifact.icon, size: 80, color: artifact.color),
            ),
            const SizedBox(height: 20),
            Text(artifact.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
            const SizedBox(height: 10),
            Text(artifact.description, textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            const Text("+50 HONOR DE GUERRERO", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              onPressed: () => Navigator.pop(context),
              child: const Text("GUARDAR EN LA BOLSA", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(st['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), const Icon(Icons.sensors, color: Colors.blue)]),
                const SizedBox(height: 8),
                Text("Municipio: ${st['municipio']}", style: TextStyle(color: Colors.grey[600])),
                const Divider(height: 32),
                if (isLoading) const Center(child: CircularProgressIndicator())
                else if (sensors.isEmpty) const Text("No hay sensores activos.")
                else Wrap(spacing: 8, runSpacing: 8, children: sensors.map((s) => Chip(avatar: Icon(s['name'].toString().contains("Temp") ? Icons.thermostat : Icons.check_circle, size: 14, color: Colors.green), label: Text("${s['name']}: ${s['value']} ${s['unit']}", style: const TextStyle(fontSize: 12)), backgroundColor: Colors.blue[50])).toList()),
                const SizedBox(height: 24),
                const Text("Datos oficiales del Cabildo de Tenerife.", style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
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

    final isDanger = provider.isGuayotaZone(poi.municipio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              if (isDanger)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[200]!)),
                  child: Row(
                    children: [
                      Image.asset('assets/guayota.png', width: 24, height: 24),
                      const SizedBox(width: 10),
                      Expanded(child: Text("¡ZONA BAJO LA IRA DE GUAYOTA! Extrema las precauciones por el calor.", style: TextStyle(color: Colors.red[900], fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              Text(poi.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(poi.type, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              if (dist != null) Text("A ${ (dist/1000).toStringAsFixed(1) } km de ti", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const Divider(height: 30),
              const Text("Descripción", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(poi.description, style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(isDanger ? Icons.warning : Icons.check_circle_outline),
                label: Text(isDanger ? "RECLAMAR BAJO TU RIESGO" : "RECLAMAR TERRITORIO"),
                style: ElevatedButton.styleFrom(backgroundColor: isDanger ? Colors.red[900] : Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: (dist != null && dist < 500) ? () {
                  final artifact = provider.forceCheckIn(poi);
                  Navigator.pop(context);
                  if (artifact != null) _showArtifactDialog(artifact);
                } : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.bug_report, color: Colors.orange),
                label: const Text("SIMULAR VISITA (DEMO)", style: TextStyle(color: Colors.orange)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final artifact = provider.forceCheckIn(poi);
                  Navigator.pop(context);
                  if (artifact != null) _showArtifactDialog(artifact);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBICSheet(BIC bic, POIProvider provider) {
    double? dist;
    if (provider.currentPosition != null) {
      dist = Geolocator.distanceBetween(provider.currentPosition!.latitude, provider.currentPosition!.longitude, bic.lat, bic.lng);
    }

    final isDanger = provider.isGuayotaZone(bic.municipio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              if (isDanger)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[200]!)),
                  child: Row(
                    children: [
                      Image.asset('assets/guayota.png', width: 24, height: 24),
                      const SizedBox(width: 10),
                      Expanded(child: Text("¡ZONA BAJO LA IRA DE GUAYOTA! Los ancestros piden precaución por el calor.", style: TextStyle(color: Colors.red[900], fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              Text(bic.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
              Text("Patrimonio Histórico", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              const Divider(height: 30),
              Text(bic.description, style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(isDanger ? Icons.warning : Icons.check_circle_outline),
                label: Text(isDanger ? "HONRAR BAJO TU RIESGO" : "HONRAR ANCESTROS"),
                style: ElevatedButton.styleFrom(backgroundColor: isDanger ? Colors.red[900] : Colors.amber[800], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: (dist != null && dist < 500) ? () {
                  final artifact = provider.forceCheckIn(bic);
                  Navigator.pop(context);
                  if (artifact != null) _showArtifactDialog(artifact);
                } : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.bug_report, color: Colors.orange),
                label: const Text("SIMULAR VISITA (DEMO)", style: TextStyle(color: Colors.orange)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final artifact = provider.forceCheckIn(bic);
                  Navigator.pop(context);
                  if (artifact != null) _showArtifactDialog(artifact);
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Dificultad: ${it.difficulty}", style: TextStyle(fontWeight: FontWeight.bold, color: Color(int.parse(it.difficultyColor.replaceFirst('#', '0xFF'))))),
                if (it.isCircular) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.cached, size: 14, color: Colors.blue), SizedBox(width: 4), Text("CIRCULAR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue))])),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.straighten, color: Colors.grey, size: 18), const SizedBox(width: 8), Text("Distancia: ${it.distancia.toStringAsFixed(0)} m", style: const TextStyle(fontSize: 16))]),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text("INICIAR SEGUIMIENTO DE RUTA"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () {
                provider.setHighlightedItinerary(it.matricula);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ruta ${it.matricula} activada. ¡Sigue la línea!")));
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              label: const Text("SIMULAR RUTA COMPLETADA (DEMO)", style: TextStyle(color: Colors.orange)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                provider.forceCheckIn(it);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡Ruta ${it.matricula} completada! Nuevos senderos revelados.")));
              },
            ),
          ],
        ),
      ),
    );
  }
}