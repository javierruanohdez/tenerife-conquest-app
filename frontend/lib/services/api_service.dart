import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/poi.dart';
import '../models/itinerary.dart';
import '../models/bic.dart';

class ApiService {
  String get baseUrl {
    // Si estamos en Web, usamos localhost. Si no, la IP de red.
    const String localIp = kIsWeb ? "127.0.0.1" : "192.168.1.145";
    const String port = "3000";
    return "http://$localIp:$port/api";
  }

  Future<List<POI>> fetchPOIs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pois'));
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => POI.fromJson(item)).toList();
      } else {
        throw "Error fetching POIs";
      }
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<Itinerary>> fetchItineraries() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/itinerarios'));
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => Itinerary.fromJson(item)).toList();
      } else {
        throw "Error fetching Itineraries";
      }
    } catch (e) {
      print(e);
      return [];
    }
  }

    Future<List<BIC>> fetchBICs() async {
      try {
        final response = await http.get(Uri.parse('$baseUrl/bics'));
        if (response.statusCode == 200) {
          List<dynamic> body = json.decode(response.body);
          return body.map((dynamic item) => BIC.fromJson(item)).toList();
        } else {
          throw "Error fetching BICs";
        }
      } catch (e) {
        print(e);
        return [];
      }
    }
  
    Future<List<dynamic>> fetchEntornosRaw() async {
      try {
        final response = await http.get(Uri.parse('$baseUrl/entornos'));
        if (response.statusCode == 200) {
          return (json.decode(response.body)['features'] as List);
        }
        return [];
      } catch (e) {
        return [];
      }
    }
  
    Future<List<dynamic>> fetchBordersRaw() async {
        try {

        final response = await http.get(Uri.parse('$baseUrl/borders'));

        if (response.statusCode == 200) {

          return json.decode(response.body);

        }

        return [];

      } catch (e) {

        return [];

      }

    }

  

      Future<Map<String, dynamic>?> fetchRecommendation() async {

  

        try {

  

          final response = await http.get(Uri.parse('$baseUrl/recommendation'));

  

          if (response.statusCode == 200) {

  

            return json.decode(response.body);

  

          }

  

          return null;

  

        } catch (e) {

  

          return null;

  

        }

  

      }

  

    

  

      Future<List<dynamic>> fetchWeather() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/weather'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchStationSensors(int stationId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/weather/station/$stationId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> sendReport(int poiId, String type, String comment) async {

  

        try {

  

          final response = await http.post(

  

            Uri.parse('$baseUrl/report'),

  

            headers: {"Content-Type": "application/json"},

  

            body: json.encode({"poiId": poiId, "type": type, "comment": comment}),

  

          );

  

          return response.statusCode == 200;

  

        } catch (e) {

  

          return false;

  

        }

  

      }

  

    }

  

    

  