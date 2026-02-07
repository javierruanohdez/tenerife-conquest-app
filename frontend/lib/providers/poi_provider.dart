import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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

class POIProvider with ChangeNotifier {
  List<POI> _allPois = [];
  List<POI> _filteredPois = [];
  List<Itinerary> _itineraries = [];
  List<BIC> _bics = [];
  List<BIC> _filteredBics = [];
  List<List<LatLng>> _borders = [];
  Set<int> _discoveredPoiIds = {};
  List<Visit> _visits = [];
  
  String _selectedEspacio = "Todos";
  Itinerary? _selectedItinerary;
  Map<String, dynamic>? _recommendation;
  
  Position? _currentPosition;
  int _points = 0;
  final ApiService _apiService = ApiService();

  List<POI> get pois => _filteredPois;
  List<POI> get allPois => _allPois;
  List<Itinerary> get itineraries => _itineraries;
  List<BIC> get bics => _filteredBics;
  List<List<LatLng>> get borders => _borders;
  Set<int> get discoveredPoiIds => _discoveredPoiIds;
  List<Visit> get visits => _visits;
  Position? get currentPosition => _currentPosition;
  int get points => _points;
  String get selectedEspacio => _selectedEspacio;
  Itinerary? get selectedItinerary => _selectedItinerary;
  Map<String, dynamic>? get recommendation => _recommendation;

  Future<void> loadData() async {
    _allPois = await _apiService.fetchPOIs();
    _itineraries = await _apiService.fetchItineraries();
    _bics = await _apiService.fetchBICs();
    _recommendation = await _apiService.fetchRecommendation();
    
    final rawBorders = await _apiService.fetchBordersRaw();
    _borders = rawBorders.map((path) {
      return (path as List).map((point) {
        return LatLng((point as List)[0], point[1]);
      }).toList();
    }).toList();

    _filterPois();
    _filterBics();

    // DEMO: Desbloquear algunos puntos al inicio
    if (_allPois.isNotEmpty) {
      _discoveredPoiIds.add(_allPois[0].id);
      if (_allPois.length > 5) _discoveredPoiIds.add(_allPois[5].id);
      if (_allPois.length > 10) _discoveredPoiIds.add(_allPois[10].id);
    }

    notifyListeners();
  }

  void setFilter(String espacio) {
    _selectedEspacio = espacio;
    _selectedItinerary = null;
    _filterPois();
    _filterBics();
    notifyListeners();
  }

  void selectItinerary(Itinerary it) {
    _selectedItinerary = it;
    _selectedEspacio = "Ruta: ${it.matricula}";
    
    List<String> itEspacios = it.espacios.split('|').map((e) => e.trim()).toList();
    _filteredPois = _allPois.where((p) => 
      itEspacios.any((esp) => p.enp.contains(esp))
    ).toList();

    _filteredBics = _bics.where((b) => 
      it.municipios.contains(b.municipio)
    ).toList();
    
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

  POI? getFirstPoiInEspacio(String espacio) {
    try {
      return _allPois.firstWhere((p) => p.enp.contains(espacio));
    } catch (e) {
      return null;
    }
  }

  POI? getPoiForItinerary(Itinerary it) {
    List<String> itEspacios = it.espacios.split('|').map((e) => e.trim()).toList();
    try {
      return _allPois.firstWhere((p) => itEspacios.any((esp) => p.enp.contains(esp)));
    } catch (e) {
      return null;
    }
  }

  void updateLocation(Position position) {
    _currentPosition = position;
    notifyListeners();
  }

  void forceCheckIn(POI poi) {
    _points += 100;
    _discoveredPoiIds.add(poi.id);
    _visits.add(Visit(poi: poi, date: DateTime.now()));
    notifyListeners();
  }

  void checkIn(POI poi) {
    if (_currentPosition == null) return;

    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      poi.lat,
      poi.lng,
    );

    if (distance <= 500) {
      int reward = poi.saturation == 'low' ? 200 : (poi.saturation == 'medium' ? 100 : 50);
      _points += reward;
      _discoveredPoiIds.add(poi.id);
      _visits.add(Visit(poi: poi, date: DateTime.now()));
      notifyListeners();
    }
  }

  Future<void> sendReport(int poiId, String type, String comment) async {
    bool success = await _apiService.sendReport(poiId, type, comment);
    if (success) {
      _points += 50; // Recompensa por Ciencia Ciudadana
      notifyListeners();
    }
  }
}
