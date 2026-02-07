class Itinerary {
  final int id;
  final String name;
  final String matricula;
  final String description;
  final String clase;
  final String modalidad;
  final String inicio;
  final String fin;
  final String distancia;
  final String desnivelPos;
  final String desnivelNeg;
  final String municipios;
  final String espacios;
  final List<dynamic>? paths;
  final List<dynamic>? startPoint;

  Itinerary({
    required this.id,
    required this.name,
    required this.matricula,
    required this.description,
    required this.clase,
    required this.modalidad,
    required this.inicio,
    required this.fin,
    required this.distancia,
    required this.desnivelPos,
    required this.desnivelNeg,
    required this.municipios,
    required this.espacios,
    this.paths,
    this.startPoint,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'],
      name: json['name'] ?? "",
      matricula: json['matricula'] ?? "",
      description: json['description'] ?? "Ruta oficial de Tenerife.",
      clase: json['clase'] ?? "",
      modalidad: json['modalidad'] ?? "",
      inicio: json['inicio'] ?? "",
      fin: json['fin'] ?? "",
      distancia: json['distancia']?.toString() ?? "0",
      desnivelPos: json['desnivel_pos']?.toString() ?? "0",
      desnivelNeg: json['desnivel_neg']?.toString() ?? "0",
      municipios: json['municipios'] ?? "",
      espacios: json['espacios'] ?? "",
      paths: json['paths'],
      startPoint: json['startPoint'],
    );
  }
}
