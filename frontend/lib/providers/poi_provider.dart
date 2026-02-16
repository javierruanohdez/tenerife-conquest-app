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
  List<Itinerary> _itineraries = [];
  List<BIC> _bics = [];
  List<BIC> _filteredBics = [];
  List<MuniBorder> _borders = [];
  List<dynamic> _weatherStations = [];
  Set<int> _discoveredPoiIds = {};
  Set<String> _discoveredMunicipios = {}; 
  List<Visit> _visits = [];
  
  String _selectedEspacio = "Todos";
  Itinerary? _selectedItinerary;
  String? _highlightedItineraryId;
  bool _showAllTrails = true;
  Map<String, dynamic>? _recommendation;
  String _userName = "Yone Explorador";
  
  Position? _currentPosition;
  int _points = 0;
  final ApiService _apiService = ApiService();

  final List<Explorer> _globalRanking = [
    Explorer(name: "Ayoze_Anaga", conquests: 45),
    Explorer(name: "Elena_Teide", conquests: 38),
    Explorer(name: "Yone Explorador", conquests: 0, isMe: true),
    Explorer(name: "Marcos_Sur", conquests: 22),
    Explorer(name: "Guacimara_92", conquests: 15),
  ];

  final List<Explorer> _groupRanking = [
    Explorer(name: "Elena_Teide", conquests: 38),
    Explorer(name: "Yone Explorador", conquests: 0, isMe: true),
    Explorer(name: "Marcos_Sur", conquests: 22),
  ];

  List<POI> get pois => _filteredPois;
  List<POI> get allPois => _allPois;
  List<Itinerary> get itineraries => _itineraries;
  List<BIC> get bics => _filteredBics;
  List<MuniBorder> get borders => _borders;
  List<dynamic> get weatherStations => _weatherStations;
  Set<int> get discoveredPoiIds => _discoveredPoiIds;
  Set<String> get discoveredMunicipios => _discoveredMunicipios;
  List<Visit> get visits => _visits;
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
      final String muni = (st['municipio'] ?? "").toString().toUpperCase();
      final double temp = (st['temp'] as num).toDouble();
      if (temp > 30) dynamicAlerts[muni] = "CALOR (${temp.toStringAsFixed(1)}°C)";
      else if (temp < 5) dynamicAlerts[muni] = "FRIO (${temp.toStringAsFixed(1)}°C)";
    }
    return dynamicAlerts;
  }

  List<Explorer> get globalRanking {
    int myIndex = _globalRanking.indexWhere((e) => e.isMe);
    _globalRanking[myIndex] = Explorer(name: _userName, conquests: _visits.length, isMe: true);
    final list = List<Explorer>.from(_globalRanking);
    list.sort((a, b) => b.conquests.compareTo(a.conquests));
    return list;
  }

  List<Explorer> get groupRanking {
    int myIndex = _groupRanking.indexWhere((e) => e.isMe);
    _groupRanking[myIndex] = Explorer(name: _userName, conquests: _visits.length, isMe: true);
    final list = List<Explorer>.from(_groupRanking);
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
      _itineraries = results[1] as List<Itinerary>;
      _weatherStations = results[2] as List<dynamic>;
      _bics = results[3] as List<BIC>;
      final rawBorders = results[4] as List<dynamic>;
      _recommendation = results[5] as Map<String, dynamic>?;

      print("[DEBUG] POIs: ${_allPois.length}, Senderos: ${_itineraries.length}, Stations: ${_weatherStations.length}, BICs: ${_bics.length}, Borders: ${rawBorders.length}");

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
    notifyListeners();
  }

  void _filterPois() {
    if (_selectedEspacio == "Todos") _filteredPois = List.from(_allPois);
    else _filteredPois = _allPois.where((p) => p.enp.contains(_selectedEspacio)).toList();
  }

  void _filterBics() {
    if (_selectedEspacio == "Todos") _filteredBics = _bics;
    else _filteredBics = _bics.where((b) => _selectedEspacio.contains(b.municipio)).toList();
  }

  void updateLocation(Position position) {
    _currentPosition = position;
    _checkPassiveUnlocking(position);
    notifyListeners();
  }

  void _checkPassiveUnlocking(Position pos) {
    for (var poi in _allPois) {
      if (!_discoveredMunicipios.contains(poi.municipio.toUpperCase().trim())) {
        double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, poi.lat, poi.lng);
        if (dist < 2000) {
          _unlockMunicipality(poi.municipio);
          if (!_visits.any((v) => v.poi.municipio == poi.municipio)) {
             _visits.add(Visit(poi: poi, date: DateTime.now()));
          }
          return;
        }
      }
    }
  }

  void forceCheckIn(dynamic item, {String? customPhotoPath}) {
    _points += 100;
    String muni = item is POI ? item.municipio : (item as BIC).municipio;
    _unlockMunicipality(muni);
    _visits.add(Visit(
      poi: item is POI ? item : POI(
        id: item.id, name: item.name, lat: item.lat, lng: item.lng, 
        type: "BIC", saturation: "none", description: item.description, 
        enp: "", municipio: item.municipio, touristPressure: 0
      ), 
      date: DateTime.now(),
      photoUrl: customPhotoPath ?? "https://images.unsplash.com/photo-1506197603052-3cc9c3a201bd"
    ));
    notifyListeners();
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
}