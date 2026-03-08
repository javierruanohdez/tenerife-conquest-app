import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/poi_provider.dart';

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
            colors: [Colors.green[800]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(poiProvider),
              _buildIslandProgress(poiProvider),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("MISIONES ACTIVAS", 
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            _buildQuestCard(
                              "El Primer Paso",
                              "Explora el mapa y limpia tu primera zona.",
                              poiProvider.discoveredMunicipios.length > 1 ? 1.0 : 0.5,
                              Icons.map,
                            ),
                            _buildQuestCard(
                              "Cazador de Historia",
                              "Captura tu primer Bien de Interés Cultural.",
                              poiProvider.visits.any((v) => v.poi.type == "BIC") ? 1.0 : 0.0,
                              Icons.account_balance,
                            ),
                            _buildQuestCard(
                              "Influencer Sostenible",
                              "Comparte una captura en tus grupos.",
                              0.0, // Simulado
                              Icons.share,
                            ),
                            _buildQuestCard(
                              "Dominio del Norte",
                              "Desbloquea 5 municipios del norte.",
                              (poiProvider.discoveredMunicipios.length / 5).clamp(0.0, 1.0),
                              Icons.terrain,
                            ),
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

  Widget _buildTopBar(POIProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("CONQUISTA TENERIFE", 
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
              Text("Nivel: ${provider.points > 500 ? 'Guardián' : 'Explorador'}", 
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.notifications_none, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildIslandProgress(POIProvider provider) {
    double progress = provider.discoveredMunicipios.length / 31;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progreso de Conquista", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("${(progress * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            color: Colors.lightGreenAccent,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(String title, String subtitle, double progress, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: progress == 1.0 ? Colors.green[100] : Colors.grey[100],
              child: Icon(icon, color: progress == 1.0 ? Colors.green : Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, minHeight: 4, borderRadius: BorderRadius.circular(2)),
                ],
              ),
            ),
            if (progress == 1.0) const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
