import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/poi.dart';
import '../models/itinerary.dart';
import '../models/bic.dart';

class ApiService {
  String get baseUrl {
    const String localIp = kIsWeb ? "127.0.0.1" : "192.168.1.145";
    const String port = "3000";
    return "http://$localIp:$port/api";
  }

  Future<List<POI>> fetchPOIs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pois')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => POI.fromJson(item)).toList();
      }
    } catch (e) {
      print("[ApiService] Fallo conexión a backend para POIs, cargando local...");
    }

    // Fallback local
    try {
      final String localData = await rootBundle.loadString('assets/data/pois.json');
      List<dynamic> body = json.decode(localData);
      return body.map((dynamic item) => POI.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Itinerary>> fetchItineraries() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/itinerarios')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => Itinerary.fromJson(item)).toList();
      }
    } catch (e) {
      print("[ApiService] Fallo conexión a backend para Itinerarios, cargando local...");
    }
    return []; // Para itinerarios no tenemos mock local complejo aún
  }

    Future<List<BIC>> fetchBICs() async {
      try {
        final response = await http.get(Uri.parse('$baseUrl/bics')).timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          List<dynamic> body = json.decode(response.body);
          return body.map((dynamic item) => BIC.fromJson(item)).toList();
        }
      } catch (e) {
        print("[ApiService] Fallo conexión a backend para BICs, cargando local...");
      }
      return [];
    }

    Future<List<dynamic>> fetchBordersRaw() async {
        try {
        final response = await http.get(Uri.parse('$baseUrl/borders')).timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
      } catch (e) {
        print("[ApiService] Fallo conexión a backend para Borders, cargando local...");
      }

      // Fallback local para fronteras
      try {
        final String localData = await rootBundle.loadString('assets/data/borders.json');
        return json.decode(localData);
      } catch (e) {
        return [];
      }
    }

    Future<Map<String, dynamic>?> fetchRecommendation() async {
        try {
          final response = await http.get(Uri.parse('$baseUrl/recommendation')).timeout(const Duration(seconds: 2));
          if (response.statusCode == 200) {
            return json.decode(response.body);
          }
        } catch (e) {
          return null;
        }
        return null;
      }

      Future<List<dynamic>> fetchWeather() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/weather')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchStationSensors(int stationId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/weather/station/$stationId')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<bool> sendReport(int poiId, String type, String comment) async {
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/report'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"poiId": poiId, "type": type, "comment": comment}),
          ).timeout(const Duration(seconds: 2));
          return response.statusCode == 200;
        } catch (e) {
          return false;
        }
      }
    }


  

    

  