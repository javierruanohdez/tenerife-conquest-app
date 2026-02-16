class BIC {
  final int id;
  final String name;
  final String category;
  final String municipio;
  final String description;
  final String url;
  final double lat;
  final double lng;

  BIC({
    required this.id,
    required this.name,
    required this.category,
    required this.municipio,
    required this.description,
    required this.url,
    required this.lat,
    required this.lng,
  });

  factory BIC.fromJson(Map<String, dynamic> json) {
    return BIC(
      id: json['id'],
      name: json['name'] ?? "Sin nombre",
      category: json['category'] ?? "",
      municipio: json['municipio'] ?? "",
      description: json['description'] ?? "",
      url: json['url'] ?? "",
      lat: (json['lat'] as num?)?.toDouble() ?? 28.2916,
      lng: (json['lng'] as num?)?.toDouble() ?? -16.6291,
    );
  }
}
