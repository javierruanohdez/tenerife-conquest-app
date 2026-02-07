import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/poi_provider.dart';
import 'map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final poiProvider = Provider.of<POIProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[800]!, Colors.green[50]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: "Cabecera de usuario",
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Hola, Explorador", 
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      Text("Nivel: ${poiProvider.points > 500 ? 'Guardián de la Isla' : 'Eco-Viajero'}", 
                        style: const TextStyle(color: Colors.white70, fontSize: 18)),
                    ],
                  ),
                ),
              ),
              
              // Tarjeta de Puntos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Semantics(
                  label: "Puntuación actual",
                  value: "${poiProvider.points} Eco-Puntos acumulados",
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${poiProvider.points}", 
                                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green[800])),
                              const Text("Eco-Puntos acumulados", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          Icon(Icons.eco, size: 50, color: Colors.green[400], semanticLabel: "Icono de sostenibilidad"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Semantics(
                        header: true,
                        child: const Text("¿Qué quieres hacer hoy?", 
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                      
                      _actionCard(
                        context,
                        "Explorar el Mapa",
                        "Encuentra puntos de interés y rutas en tiempo real.",
                        Icons.map,
                        Colors.blue,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen())),
                      ),
                      
                      _actionCard(
                        context,
                        "Ruta Recomendada",
                        poiProvider.recommendation != null 
                          ? "Hoy: ${poiProvider.recommendation!['poi']['name']} (${poiProvider.recommendation!['poi']['saturation']})"
                          : "Calculando mejor ruta...",
                        Icons.auto_awesome,
                        Colors.orange,
                        () {
                          if (poiProvider.recommendation != null) {
                            // En una versión completa aquí navegaríamos centrando el mapa
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen()));
                          }
                        },
                      ),

                      const SizedBox(height: 20),
                      Semantics(
                        label: "Información de impacto ambiental",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Tu impacto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text("Has ayudado a reducir la presión turística en un 12% este mes visitando zonas alternativas.",
                              style: TextStyle(color: Colors.grey[600], height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: "Botón: $title. $subtitle",
      onTapHint: "Abrir $title",
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, semanticLabel: ""), // Hide redundant icon
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right, semanticLabel: "Ir"),
          onTap: onTap,
        ),
      ),
    );
  }
}
