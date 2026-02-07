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
  Set<int> _discoveredPoiIds = {};
  Set<String> _discoveredMunicipios = {}; 
  List<Visit> _visits = [];
  
  Map<String, String> _activeAlerts = {
    "SANTA CRUZ DE TENERIFE": "ALERTA POR VIENTO",
    "OROTAVA (LA)": "RIESGO DE INCENDIO",
  };
  
  String _selectedEspacio = "Todos";
  Itinerary? _selectedItinerary;
  String? _highlightedItineraryId;
  bool _showAllTrails = true; // CAMBIADO A TRUE PARA TESTEO
  Map<String, dynamic>? _recommendation;
  
  Position? _currentPosition;
  int _points = 0;
  final ApiService _apiService = ApiService();

  // DATOS DE RANKING SIMULADOS
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
  Set<int> get discoveredPoiIds => _discoveredPoiIds;
  Set<String> get discoveredMunicipios => _discoveredMunicipios;
  List<Visit> get visits => _visits;
  Map<String, String> get activeAlerts => _activeAlerts;
  Position? get currentPosition => _currentPosition;
  int get points => _points;
  String get selectedEspacio => _selectedEspacio;
  Itinerary? get selectedItinerary => _selectedItinerary;
  String? get highlightedItineraryId => _highlightedItineraryId;
  bool get showAllTrails => _showAllTrails;
  Map<String, dynamic>? get recommendation => _recommendation;

  List<Explorer> get globalRanking {
    int myIndex = _globalRanking.indexWhere((e) => e.isMe);
    _globalRanking[myIndex] = Explorer(name: "Yone Explorador", conquests: _visits.length, isMe: true);
    final list = List<Explorer>.from(_globalRanking);
    list.sort((a, b) => b.conquests.compareTo(a.conquests));
    return list;
  }

  List<Explorer> get groupRanking {
    int myIndex = _groupRanking.indexWhere((e) => e.isMe);
    _groupRanking[myIndex] = Explorer(name: "Yone Explorador", conquests: _visits.length, isMe: true);
    final list = List<Explorer>.from(_groupRanking);
    list.sort((a, b) => b.conquests.compareTo(a.conquests));
    return list;
  }

  Future<void> loadData() async {
    try {
      _allPois = await _apiService.fetchPOIs();
      _itineraries = await _apiService.fetchItineraries();
      _bics = await _apiService.fetchBICs();
      _recommendation = await _apiService.fetchRecommendation();
      
      final rawBorders = await _apiService.fetchBordersRaw();
      _borders = rawBorders.map((b) {
        final name = b['name'] as String;
        final geom = b['geometry']['coordinates'] as List;
        List<List<LatLng>> paths = [];
        if (b['geometry']['type'] == 'Polygon') {
          paths.add((geom[0] as List).map((p) => LatLng(p[1], p[0])).toList());
        } else {
          for (var poly in geom) {
            paths.add((poly[0] as List).map((p) => LatLng(p[1], p[0])).toList());
          }
        }
        return MuniBorder(name: name, paths: paths);
      }).toList();

      _filterPois();
      _filterBics();

      if (_allPois.isNotEmpty) {
        _unlockMunicipality(_allPois[0].municipio);
      }
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      notifyListeners();
    }
  }

  void _unlockMunicipality(String muni) {
    if (_discoveredMunicipios.contains(muni)) return;
    _discoveredMunicipios.add(muni);
    
    try { Vibration.vibrate(duration: 100); } catch (e) {}
    
    final sameMuniPois = _allPois.where((p) => p.municipio == muni);
    for (var p in sameMuniPois) { _discoveredPoiIds.add(p.id); }
    
    final sameMuniBics = _bics.where((b) => b.municipio == muni);
    for (var b in sameMuniBics) { _discoveredPoiIds.add(b.id); }
  }

  void setFilter(String espacio) {
    _selectedEspacio = espacio;
    _selectedItinerary = null;
    _filterPois();
    _filterBics();
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
    if (_selectedEspacio == "Todos") {
      _filteredPois = List.from(_allPois);
    } else {
      _filteredPois = _allPois.where((p) => p.enp.contains(_selectedEspacio)).toList();
    }
  }

  void _filterBics() {
    if (_selectedEspacio == "Todos") {
      _filteredBics = _bics;
    } else {
      _filteredBics = _bics.where((b) => _selectedEspacio.contains(b.municipio)).toList();
    }
  }

  void updateLocation(Position position) {
    _currentPosition = position;
    _checkPassiveUnlocking(position);
    notifyListeners();
  }

  void _checkPassiveUnlocking(Position pos) {
    for (var poi in _allPois) {
      if (!_discoveredMunicipios.contains(poi.municipio)) {
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
    try { Vibration.vibrate(pattern: [0, 100, 50, 100]); } catch (e) {}
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
    return minDistance < 1000 ? closest : null;
  }

  Future<bool> sendReport(int poiId, String type, String comment) async {
    bool success = await _apiService.sendReport(poiId, type, comment);
    if (success) { _points += 50; notifyListeners(); }
    return success;
  }
}
