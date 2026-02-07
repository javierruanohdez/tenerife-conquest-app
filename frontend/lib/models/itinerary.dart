class Itinerary {
  final int id;
  final String name;
  final String matricula;
  final String distancia;
  final String municipios;
  final String espacios;
  final String inicio;
  final String fin;

  Itinerary({
    required this.id,
    required this.name,
    required this.matricula,
    required this.distancia,
    required this.municipios,
    required this.espacios,
    required this.inicio,
    required this.fin,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'],
      name: json['name'] ?? "Sin nombre",
      matricula: json['matricula'] ?? "",
      distancia: json['distancia'] ?? "0",
      municipios: json['municipios'] ?? "",
      espacios: json['espacios'] ?? "",
      inicio: json['inicio'] ?? "",
      fin: json['fin'] ?? "",
    );
  }
}
