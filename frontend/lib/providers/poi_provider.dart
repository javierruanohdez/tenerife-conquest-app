import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';
import '../models/poi.dart';
import '../models/itinerary.dart';
import '../models/bic.dart';
import '../services/api_service.dart';

class Visit {
  final POI poi;
  final DateTime date;
  final String photoUrl;
  Visit({required this.poi, required this.date, this.photoUrl = "https://images.unsplash.com/photo-1506197603052-3cc9c3a201bd"});
}

class Artifact {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  Artifact({required this.name, required this.description, required this.icon, required this.color});
}

class LegendaryBadge {
  final String name;
  final String imagePath;
  final bool isUnlocked;
  LegendaryBadge({required this.name, required this.imagePath, required this.isUnlocked});
}

class EventMission {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final IconData icon;
  final DateTime startDate;
  final DateTime endDate;
  final String condition; // Ej: "visit_type:Playa:3" o "muni_checkin:La_Orotava"

  EventMission({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.icon,
    required this.startDate,
    required this.endDate,
    required this.condition,
  });

  bool get isActive => DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  bool isCompleted(POIProvider provider) {
    if (condition.startsWith("visit_type:")) {
      final parts = condition.split(":");
      final type = parts[1];
      final count = int.parse(parts[2]);
      return provider.visits.where((v) => v.poi.type.toLowerCase().contains(type.toLowerCase())).length >= count;
    }
    if (condition.startsWith("muni_checkin:")) {
      final muni = condition.split(":")[1];
      return provider.visits.any((v) => v.poi.municipio.toLowerCase().contains(muni.toLowerCase()));
    }
    // Añadir más condiciones según sea necesario
    return false;
  }
}

class Explorer {
  final String name;
  final int conquests;
  final bool isMe;
  Explorer({required this.name, required this.conquests, this.isMe = false});
}

class MuniBorder {
  final String name;
  final List<List<LatLng>> paths;
  MuniBorder({required this.name, required this.paths});
}

class POIProvider with ChangeNotifier {
  List<POI> _allPois = [];
  List<POI> _filteredPois = [];
  List<Itinerary> _allItineraries = [];
  List<Itinerary> _filteredItineraries = [];
  List<BIC> _bics = [];
  List<BIC> _filteredBics = [];
  List<MuniBorder> _borders = [];
  List<dynamic> _weatherStations = [];
  final Set<int> _discoveredPoiIds = {};
  final Set<String> _discoveredMunicipios = {}; 
  final Set<String> _completedItineraryIds = {};
  final List<Visit> _visits = [];
  double _totalDistance = 0.0;
  final List<Artifact> _inventory = [
    Artifact(name: "Gánigo de Barro", description: "Vasija ancestral usada para ofrendas a los dioses y guardar leche de cabra.", icon: Icons.local_dining, color: Colors.brown),
    Artifact(name: "Tabona de Obsidiana", description: "Piedra volcánica negra tallada para ser usada como cuchillo de gran precisión.", icon: Icons.architecture, color: Colors.grey),
  ];
  
  // Misiones de evento (simuladas con fechas)
  final List<EventMission> _allEventMissions = [
    EventMission(
      id: "EVT001",
      title: "Solsticio de Verano",
      description: "Visita 3 POIs de playa en una semana.",
      xpReward: 300,
      icon: Icons.beach_access,
      startDate: DateTime.now().subtract(const Duration(days: 10)), // Pasada
      endDate: DateTime.now().subtract(const Duration(days: 3)),
      condition: "visit_type:Playa:3",
    ),
    EventMission(
      id: "EVT002",
      title: "Despertar del Teide",
      description: "Haz check-in en cualquier POI del municipio 'La Orotava' o 'Guía de Isora'.",
      xpReward: 500,
      icon: Icons.fireplace,
      startDate: DateTime.now().subtract(const Duration(days: 2)), // Activa
      endDate: DateTime.now().add(const Duration(days: 5)),
      condition: "muni_checkin:La Orotava",
    ),
    EventMission(
      id: "EVT003",
      title: "Ruta de la Vendimia",
      description: "Visita 2 bodegas o viñedos en la zona de 'Tacoronte'.",
      xpReward: 400,
      icon: Icons.wine_bar,
      startDate: DateTime.now().add(const Duration(days: 10)), // Futura
      endDate: DateTime.now().add(const Duration(days: 17)),
      condition: "visit_type:Bodega:2",
    ),
  ];

  List<EventMission> get activeEventMissions => _allEventMissions.where((m) => m.isActive).toList();
  
  String _selectedEspacio = "Todos";
  Itinerary? _selectedItinerary;
  String? _highlightedItineraryId;
  bool _showAllTrails = true;
  Map<String, dynamic>? _recommendation;
  String _userName = "Yone Explorador";
  
  Position? _currentPosition;
  int _points = 0;
  final ApiService _apiService = ApiService();

  List<Artifact> get inventory => _inventory;

  List<LegendaryBadge> get legendaryBadges {
    return [
      LegendaryBadge(
        name: "Drago Milenario",
        imagePath: "assets/badges/hevisitadoeldragomilenario.jpeg",
        isUnlocked: _visits.any((v) => v.poi.name.toUpperCase().contains("DRAGO")),
      ),
      LegendaryBadge(
        name: "El Teide",
        imagePath: "assets/badges/hevisitadoelteide.jpeg",
        isUnlocked: _visits.any((v) => v.poi.name.toUpperCase().contains("TEIDE")),
      ),
      LegendaryBadge(
        name: "La Laguna",
        imagePath: "assets/badges/hevisitadolalaguna.jpeg",
        isUnlocked: _visits.any((v) => v.poi.municipio.contains("LAGUNA")),
      ),
      LegendaryBadge(
        name: "Maestro de Miradores",
        imagePath: "assets/badges/hevisitadotodoslosmiradores.jpeg",
        isUnlocked: _visits.where((v) => v.poi.type.toUpperCase().contains("MIRADOR")).length >= 3,
      ),
      LegendaryBadge(
        name: "Visitante Costero",
        imagePath: "assets/badges/Soyvisitantecostero.jpeg",
        isUnlocked: _visits.where((v) => v.poi.type.toUpperCase().contains("PLAYA") || v.poi.type.toUpperCase().contains("COSTA")).length >= 3,
      ),
    ];
  }

  // --- GAMIFICATION LOGIC ---
  int get level => (_points / 500).floor() + 1;
  double get levelProgress => (_points % 500) / 500;
  
  String get levelName {
    if (level >= 10) return "Mencey Legendario";
    if (level >= 7) return "Conquistador de Cumbres";
    if (level >= 5) return "Guardián de la Isla";
    if (level >= 3) return "Explorador de Barrancos";
    return "Guanchito Aprendiz";
  }
  // ---------------------------

  final List<Explorer> _globalRanking = [
    Explorer(name: "Bentor_Taoro", conquests: 45),
    Explorer(name: "Beneharo_Anaga", conquests: 38),
    Explorer(name: "Yone Explorador", conquests: 0, isMe: true),
    Explorer(name: "Pelicar_Adeje", conquests: 22),
    Explorer(name: "Dacil_Abona", conquests: 15),
  ];

  final List<Explorer> _groupRanking = [
    Explorer(name: "Beneharo_Anaga", conquests: 38),
    Explorer(name: "Yone Explorador", conquests: 0, isMe: true),
    Explorer(name: "Pelicar_Adeje", conquests: 22),
  ];

  List<POI> get pois => _filteredPois;
  List<POI> get allPois => _allPois;
  List<Itinerary> get itineraries => _filteredItineraries;
  List<BIC> get bics => _filteredBics;
  List<MuniBorder> get borders => _borders;
  List<dynamic> get weatherStations => _weatherStations;
  Set<int> get discoveredPoiIds => _discoveredPoiIds;
  Set<String> get discoveredMunicipios => _discoveredMunicipios;
  List<Visit> get visits => _visits;
  double get totalDistance => _totalDistance;
  Position? get currentPosition => _currentPosition;
  int get points => _points;
  String get selectedEspacio => _selectedEspacio;
  Itinerary? get selectedItinerary => _selectedItinerary;
  String? get highlightedItineraryId => _highlightedItineraryId;
  bool get showAllTrails => _showAllTrails;
  Map<String, dynamic>? get recommendation => _recommendation;
  String get userName => _userName;

  Map<String, String> get activeAlerts {
    Map<String, String> dynamicAlerts = {};
    for (var st in _weatherStations) {
      if (st['temp'] == null) continue;
      final String muni = (st['municipio'] ?? "").toString().toUpperCase().trim();
      final double temp = (st['temp'] as num).toDouble();
      if (temp > 35) {
        dynamicAlerts[muni] = "LA IRA DE GUAYOTA (CALOR EXTREMO: ${temp.toStringAsFixed(1)}°C)";
      } else if (temp < 5) dynamicAlerts[muni] = "SUSURRO DE IZAÑA (FRÍO INTENSO: ${temp.toStringAsFixed(1)}°C)";
    }
    return dynamicAlerts;
  }

  bool isGuayotaZone(String municipio) {
    final muni = municipio.toUpperCase().trim();
    return activeAlerts.containsKey(muni);
  }

  double getMuniOpacity(String muniName) {
    final m = muniName.toUpperCase().trim();
    
    // Contamos cuántos POIs/BICs únicos se han visitado en este municipio
    int uniqueVisitsCount = _visits
        .where((v) => v.poi.municipio.toUpperCase().trim() == m)
        .map((v) => v.poi.id)
        .toSet()
        .length;
    
    // Contamos senderos completados que pasan por este municipio
    int trailsCount = _allItineraries.where((it) => 
      _completedItineraryIds.contains(it.matricula) && 
      it.municipios.toUpperCase().contains(m)
    ).length;

    int totalDiscoveries = uniqueVisitsCount + trailsCount;

    if (totalDiscoveries == 0) return 0.85;
    if (totalDiscoveries == 1) return 0.60;
    if (totalDiscoveries == 2) return 0.40;
    if (totalDiscoveries == 3) return 0.20;
    return 0.05; // Muy claro pero aún con un toque de niebla
  }

  List<Explorer> get globalRanking {
    final list = List<Explorer>.from(_globalRanking);
    int myIndex = list.indexWhere((e) => e.isMe);
    if (myIndex != -1) {
      list[myIndex] = Explorer(name: _userName, conquests: _visits.length, isMe: true);
    }
    list.sort((a, b) => b.conquests.compareTo(a.conquests));
    return list;
  }

  List<Explorer> get groupRanking {
    final list = List<Explorer>.from(_groupRanking);
    int myIndex = list.indexWhere((e) => e.isMe);
    if (myIndex != -1) {
      list[myIndex] = Explorer(name: _userName, conquests: _visits.length, isMe: true);
    }
    list.sort((a, b) => b.conquests.compareTo(a.conquests));
    return list;
  }

  void updateUserName(String newName) {
    _userName = newName;
    notifyListeners();
  }

  Future<void> loadData() async {
    print("[DEBUG] INICIANDO CARGA DE DATOS...");
    try {
      final results = await Future.wait([
        _apiService.fetchPOIs(),
        _apiService.fetchItineraries(),
        _apiService.fetchWeather(),
        _apiService.fetchBICs(),
        _apiService.fetchBordersRaw(),
        _apiService.fetchRecommendation(),
      ]);

      _allPois = results[0] as List<POI>;
      _allItineraries = results[1] as List<Itinerary>;
      _weatherStations = results[2] as List<dynamic>;
      _bics = results[3] as List<BIC>;
      final rawBorders = results[4] as List<dynamic>;
      _recommendation = results[5] as Map<String, dynamic>?;

      print("[DEBUG] POIs: ${_allPois.length}, Senderos: ${_allItineraries.length}, Stations: ${_weatherStations.length}, BICs: ${_bics.length}, Borders: ${rawBorders.length}");

      _borders = rawBorders.map((b) {
        final name = b['name'] as String;
        final geom = b['geometry'];
        List<List<LatLng>> paths = [];
        
        if (geom['type'] == 'Polygon') {
          final rings = geom['coordinates'] as List;
          paths.add((rings[0] as List).map((p) => LatLng(p[1].toDouble(), p[0].toDouble())).toList());
        } else if (geom['type'] == 'MultiPolygon') {
          final polygons = geom['coordinates'] as List;
          for (var poly in polygons) {
            final rings = poly as List;
            paths.add((rings[0] as List).map((p) => LatLng(p[1].toDouble(), p[0].toDouble())).toList());
          }
        }
        return MuniBorder(name: name, paths: paths);
      }).toList();

      _filterPois();
      _filterBics();
      _filterItineraries();
      
      // Desbloqueo inicial (solo si no hay nada descubierto)
      if (_discoveredMunicipios.isEmpty && _allPois.isNotEmpty) {
        _unlockMunicipality(_allPois[0].municipio);
      }
      
      print("[DEBUG] CARGA COMPLETADA EXITOSAMENTE. Municipios descubiertos: ${_discoveredMunicipios.length}");
    } catch (e, stack) {
      print("[ERROR] FALLO CRITICO EN CARGA: $e");
      print(stack);
    } finally {
      notifyListeners();
    }
  }

  void _unlockMunicipality(String muni) {
    String m = muni.toUpperCase().trim();
    if (m == "TENERIFE" || m == "") return;
    if (_discoveredMunicipios.contains(m)) return;
    
    print("[DEBUG] DESBLOQUEANDO MUNICIPIO: $m");
    _discoveredMunicipios.add(m);
    
    try {
      Vibration.hasVibrator().then((has) {
        if (has == true) Vibration.vibrate(duration: 100);
      });
    } catch (e) {}
    
    final sameMuniPois = _allPois.where((p) => p.municipio.toUpperCase().trim() == m);
    for (var p in sameMuniPois) { _discoveredPoiIds.add(p.id); }
    
    final sameMuniBics = _bics.where((b) => b.municipio.toUpperCase().trim() == m);
    for (var b in sameMuniBics) { _discoveredPoiIds.add(b.id); }

    _filterPois();
    _filterBics();
    _filterItineraries();
  }

  void setFilter(String espacio) {
    _selectedEspacio = espacio;
    _selectedItinerary = null;
    _filterPois(); _filterBics();
    notifyListeners();
  }

  void setHighlightedItinerary(String? id) {
    _highlightedItineraryId = id;
    notifyListeners();
  }

  void toggleAllTrails(bool value) {
    _showAllTrails = value;
    _filterItineraries();
    notifyListeners();
  }

  void _filterItineraries() {
    if (!_showAllTrails) {
      _filteredItineraries = [];
      return;
    }

    // Agrupamos por municipios
    Map<String, List<Itinerary>> grouped = {};
    for (var it in _allItineraries) {
      final mList = it.municipios.split(',').map((e) => e.toUpperCase().trim()).toList();
      for (var m in mList) {
        grouped.putIfAbsent(m, () => []).add(it);
      }
    }

    Set<String> sampledIds = {};
    grouped.forEach((muni, list) {
      final bool isDiscovered = _discoveredMunicipios.contains(muni);
      if (isDiscovered) {
        // En municipios descubiertos, mostramos todos los que pasan por allí
        for (var it in list) sampledIds.add(it.matricula);
      } else {
        // En zonas no descubiertas, mostramos solo un 10% (min 1 si hay)
        int count = (list.length * 0.1).ceil();
        if (count < 1 && list.isNotEmpty) count = 1;
        for (var it in list.take(count)) sampledIds.add(it.matricula);
      }
    });

    // Siempre mostramos los ya completados
    sampledIds.addAll(_completedItineraryIds);

    _filteredItineraries = _allItineraries.where((it) => sampledIds.contains(it.matricula)).toList();
  }

  void _filterPois() {
    // Agrupamos por municipio para aplicar el muestreo en zonas no descubiertas
    Map<String, List<POI>> grouped = {};
    for (var p in _allPois) {
      final m = p.municipio.toUpperCase().trim();
      grouped.putIfAbsent(m, () => []).add(p);
    }

    List<POI> sampled = [];
    grouped.forEach((muni, list) {
      final bool isDiscovered = _discoveredMunicipios.contains(muni);
      if (isDiscovered) {
        sampled.addAll(list);
      } else {
        // En zonas no descubiertas, mostramos solo unos pocos (ej: 20%, min 1)
        int count = (list.length * 0.2).ceil();
        if (count < 1 && list.isNotEmpty) count = 1;
        sampled.addAll(list.take(count));
      }
    });

    _filteredPois = sampled.where((p) {
      final bool matchesEspacio = _selectedEspacio == "Todos" || p.enp.contains(_selectedEspacio);
      return matchesEspacio;
    }).toList();
  }

  void _filterBics() {
    Map<String, List<BIC>> grouped = {};
    for (var b in _bics) {
      final m = b.municipio.toUpperCase().trim();
      grouped.putIfAbsent(m, () => []).add(b);
    }

    List<BIC> sampled = [];
    grouped.forEach((muni, list) {
      final bool isDiscovered = _discoveredMunicipios.contains(muni);
      if (isDiscovered) {
        sampled.addAll(list);
      } else {
        int count = (list.length * 0.15).ceil();
        if (count < 1 && list.isNotEmpty) count = 1;
        sampled.addAll(list.take(count));
      }
    });

    _filteredBics = sampled;
  }

  void updateLocation(Position position) {
    _currentPosition = position;
    _checkPassiveUnlocking(position);
    notifyListeners();
  }

  void _checkPassiveUnlocking(Position pos) {
    bool changed = false;
    for (var poi in _allPois) {
      double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, poi.lat, poi.lng);
      if (dist < 500) {
        if (!_discoveredPoiIds.contains(poi.id)) {
          _discoveredPoiIds.add(poi.id);
          _points += 50;
          _visits.add(Visit(poi: poi, date: DateTime.now()));
          _unlockMunicipality(poi.municipio);
          changed = true;
        }
      } else if (dist < 2000) {
        if (!_discoveredMunicipios.contains(poi.municipio.toUpperCase().trim())) {
          _unlockMunicipality(poi.municipio);
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  Artifact? forceCheckIn(dynamic item, {String? customPhotoPath}) {
    _points += 100;
    String muni = "";
    if (item is POI) {
      muni = item.municipio;
      _discoveredPoiIds.add(item.id);
    } else if (item is BIC) {
      muni = item.municipio;
      _discoveredPoiIds.add(item.id);
    } else if (item is Itinerary) {
      muni = item.municipios.split(',').first; // Tomamos el primer municipio como referencia
      _totalDistance += item.distancia;
      _completedItineraryIds.add(item.matricula);
    }

    _unlockMunicipality(muni);
    _filterItineraries();
    
    if (item is! Itinerary) {
      _visits.add(Visit(
        poi: item is POI ? item : POI(
          id: item.id, name: item.name, lat: item.lat, lng: item.lng, 
          type: "BIC", saturation: "none", description: item.description, 
          enp: "", municipio: item.municipio, touristPressure: 0
        ), 
        date: DateTime.now(),
        photoUrl: customPhotoPath ?? "https://images.unsplash.com/photo-1506197603052-3cc9c3a201bd"
      ));
    }
    
    Artifact? newArtifact = _maybeDropArtifact();
    notifyListeners();
    return newArtifact;
  }

  Artifact? _maybeDropArtifact() {
    // 70% de probabilidad de encontrar algo
    final random = (DateTime.now().millisecond % 10);
    if (random > 7) return null;

    final artifacts = [
      Artifact(name: "Gánigo de Barro", description: "Vasija ancestral para ofrendas.", icon: Icons.local_dining, color: Colors.brown),
      Artifact(name: "Tabona de Obsidiana", description: "Cuchillo de piedra volcánica.", icon: Icons.architecture, color: Colors.grey),
      Artifact(name: "Pintadera Sagrada", description: "Sello de identidad de la tribu.", icon: Icons.grid_view_rounded, color: Colors.deepOrange),
      Artifact(name: "Collar de Cuentas", description: "Adorno hecho de conchas marinas.", icon: Icons.brightness_7_outlined, color: Colors.blueGrey),
    ];

    final found = artifacts[random % artifacts.length];
    
    // Evitar duplicados simples por ahora
    if (!_inventory.any((a) => a.name == found.name)) {
      _inventory.add(found);
      _points += 50; // Bonus por encontrar artefacto
      return found;
    }
    return null;
  }

  void checkIn(dynamic item) {
    if (_currentPosition == null) return;
    double distance = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, item.lat, item.lng);
    if (distance <= 500) forceCheckIn(item);
  }

  POI? get nearestPoi {
    if (_currentPosition == null || _allPois.isEmpty) return null;
    POI? closest;
    double minDistance = double.infinity;
    for (var poi in _allPois) {
      double dist = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, poi.lat, poi.lng);
      if (dist < minDistance) { minDistance = dist; closest = poi; }
    }
    return minDistance < 2000 ? closest : null;
  }

  Future<Map<String, dynamic>?> fetchStationSensors(int stationId) async {
    return await _apiService.fetchStationSensors(stationId);
  }

  Future<bool> sendReport(int poiId, String type, String comment) async {
    bool success = await _apiService.sendReport(poiId, type, comment);
    if (success) { _points += 50; notifyListeners(); }
    return success;
  }

  // --- DASHBOARD PARA EL CABILDO ---
  Map<String, dynamic> get globalConquestStats {
    // Estas serían estadísticas globales de todos los usuarios en un entorno real.
    // Para la demo, usamos las estadísticas del usuario actual como proxy.
    return {
      "municipiosConquistados": _discoveredMunicipios.length,
      "totalMunicipios": _borders.length,
      "totalArtefactos": _inventory.length,
      "totalConquistas": _visits.length,
      "reportesAmbientales": 3, // Simulado
      "impactoGuayota": { // Simulado
        "zonasAfectadas": activeAlerts.values.where((v) => v.contains("GUAYOTA")).length,
        "desviosExitosos": 2, // Cuánta gente evitó una zona peligrosa
      }
    };
  }

  LatLng? teleportToRandomMunicipality() {
    if (_borders.isEmpty) return null;
    final randomMuni = _borders[(DateTime.now().millisecond % _borders.length)];
    if (randomMuni.paths.isEmpty || randomMuni.paths[0].isEmpty) return null;

    // Calculamos un punto central simple del municipio para el teletransporte
    double avgLat = 0, avgLng = 0;
    int pointCount = 0;
    for (var path in randomMuni.paths) {
      for (var point in path) {
        avgLat += point.latitude;
        avgLng += point.longitude;
        pointCount++;
      }
    }
    
    if (pointCount > 0) {
      final center = LatLng(avgLat / pointCount, avgLng / pointCount);
      _currentPosition = Position(
        latitude: center.latitude, 
        longitude: center.longitude, 
        timestamp: DateTime.now(), 
        accuracy: 0.0, 
        altitude: 0.0, 
        altitudeAccuracy: 0,
        heading: 0.0, 
        headingAccuracy: 0,
        speed: 0.0, 
        speedAccuracy: 0.0
      );
      _checkPassiveUnlocking(_currentPosition!);
      notifyListeners();
      return center;
    }
    return null;
  }
}