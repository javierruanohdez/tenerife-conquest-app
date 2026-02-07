class BIC {
  final int id;
  final String name;
  final String category;
  final String municipio;
  final String description;
  final String url;

  BIC({
    required this.id,
    required this.name,
    required this.category,
    required this.municipio,
    required this.description,
    required this.url,
  });

  factory BIC.fromJson(Map<String, dynamic> json) {
    return BIC(
      id: json['id'],
      name: json['name'] ?? "Sin nombre",
      category: json['category'] ?? "",
      municipio: json['municipio'] ?? "",
      description: json['description'] ?? "",
      url: json['url'] ?? "",
    );
  }
}
