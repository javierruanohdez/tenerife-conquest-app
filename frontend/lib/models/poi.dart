class POI {
  final int id;
  final String name;
  final double lat;
  final double lng;
  final String type;
  final String saturation; // low, medium, high
  final int capacity;
  final String description;
  final String enp;

  POI({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
    required this.saturation,
    required this.capacity,
    required this.description,
    required this.enp,
  });

  factory POI.fromJson(Map<String, dynamic> json) {
    return POI(
      id: json['id'],
      name: json['name'] ?? "Sin nombre",
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
      type: json['type'] ?? "Interés",
      saturation: json['saturation'] ?? "low",
      capacity: json['capacity'] ?? 0,
      description: json['description'] ?? "",
      enp: json['enp'] ?? "",
    );
  }
}
