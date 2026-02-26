class Itinerary {
  final int id;
  final String name;
  final String matricula;
  final String difficulty;
  final String difficultyColor;
  final double distancia;
  final bool isCircular;
  final String municipios;
  final String description;
  final int desnivelPos;
  final String clase;
  final List<dynamic>? paths;
  final List<dynamic>? startPoint;

  Itinerary({
    required this.id,
    required this.name,
    required this.matricula,
    required this.difficulty,
    required this.difficultyColor,
    required this.distancia,
    required this.isCircular,
    required this.municipios,
    required this.description,
    required this.desnivelPos,
    required this.clase,
    this.paths,
    this.startPoint,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    // Función de ayuda para convertir cualquier cosa a double de forma segura
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Itinerary(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      matricula: json['matricula'] ?? "",
      difficulty: json['difficulty'] ?? "Baja",
      difficultyColor: json['difficultyColor'] ?? "#4CAF50",
      distancia: toDouble(json['distancia']),
      isCircular: json['isCircular'] ?? false,
      municipios: json['municipios'] ?? "",
      description: json['description'] ?? "",
      desnivelPos: toInt(json['desnivelPos']),
      clase: json['clase'] ?? "Sendero",
      paths: json['paths'],
      startPoint: json['startPoint'],
    );
  }
}
