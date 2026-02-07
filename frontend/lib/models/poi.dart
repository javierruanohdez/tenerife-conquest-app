class POI {
  final int id;
  final String name;
  final double lat;
  final double lng;
  final String type;
  final String saturation; // none
  final String description;
  final String enp;
  final String municipio;
  final int touristPressure;

  POI({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
    required this.saturation,
    required this.description,
    required this.enp,
    required this.municipio,
    this.touristPressure = 0,
  });

  factory POI.fromJson(Map<String, dynamic> json) {
    return POI(
      id: json['id'],
      name: json['name'] ?? "Sin nombre",
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      type: json['type'] ?? "Interés",
      saturation: json['saturation'] ?? "none",
      description: json['description'] ?? "",
      enp: json['enp'] ?? "",
      municipio: json['municipio'] ?? "TENERIFE",
      touristPressure: json['touristPressure'] ?? 0,
    );
  }
}
