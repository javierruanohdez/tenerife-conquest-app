import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/poi_provider.dart';

class Mission {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final IconData icon;
  final double progress; // 0.0 to 1.0

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.icon,
    required this.progress,
  });
}

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<POIProvider>(context);
    
    // Misiones dinámicas basadas en el estado real del usuario
    final List<Mission> missions = [
      Mission(
        id: "1",
        title: "El Despertar del Guerrero",
        description: "Reclama tu primer territorio en la isla.",
        xpReward: 100,
        icon: Icons.explore,
        progress: provider.visits.isNotEmpty ? 1.0 : 0.0,
      ),
      Mission(
        id: "2",
        title: "Legado de los Menceyes",
        description: "Honra a tus ancestros en 3 bienes de interés cultural sagrados.",
        xpReward: 300,
        icon: Icons.history_edu,
        progress: (provider.visits.where((v) => v.poi.type == "BIC").length / 3).clamp(0.0, 1.0),
      ),
      Mission(
        id: "3",
        title: "Señor de Añaza",
        description: "Domina 5 menceyatos de la zona norte.",
        xpReward: 500,
        icon: Icons.terrain,
        progress: (provider.discoveredMunicipios.length / 5).clamp(0.0, 1.0),
      ),
      Mission(
        id: "4",
        title: "El Oráculo del Tiempo",
        description: "Escucha el susurro de 5 estaciones meteorológicas.",
        xpReward: 200,
        icon: Icons.cloud_sync,
        progress: (provider.visits.where((v) => v.poi.type == "Estación").length / 5).clamp(0.0, 1.0), 
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Fondo oscuro estilo gaming
      appBar: AppBar(
        title: const Text("MISIONES DE CONQUISTA", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildLevelCard(provider),
          if (provider.activeEventMissions.isNotEmpty) ...[
            _buildEventMissions(context, provider),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Divider(color: Colors.white30),
            ),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: missions.length,
              itemBuilder: (context, index) {
                return _buildMissionCard(missions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventMissions(BuildContext context, POIProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.stars, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              const Text("EVENTOS CURSO", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        SizedBox(
          height: 180, // Altura fija para el scroll horizontal
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: provider.activeEventMissions.length,
            itemBuilder: (context, index) {
              final mission = provider.activeEventMissions[index];
              return Container(
                width: 250, // Ancho fijo para cada tarjeta de evento
                margin: const EdgeInsets.only(right: 15),
                child: _buildEventMissionCard(mission, provider),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventMissionCard(EventMission mission, POIProvider provider) {
    bool isCompleted = mission.isCompleted(provider);
    return Card(
      color: const Color(0xFF282828), // Fondo oscuro para eventos
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isCompleted ? Colors.amber : Colors.blueGrey, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(mission.icon, color: isCompleted ? Colors.amber : Colors.white70, size: 24),
                const SizedBox(width: 10),
                Expanded(child: Text(mission.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: isCompleted ? TextDecoration.lineThrough : null))),
                Text("+${mission.xpReward} XP", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(mission.description, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Hasta: ${mission.endDate.day}/${mission.endDate.month}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.greenAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(POIProvider provider) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green[900]!, Colors.green[600]!]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.amber,
            child: Text("${provider.level}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.levelName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: provider.levelProgress,
                    backgroundColor: Colors.white24,
                    color: Colors.amber,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text("${provider.points} XP TOTALES", style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(Mission mission) {
    bool isCompleted = mission.progress >= 1.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCompleted ? Colors.amber.withOpacity(0.5) : Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(mission.icon, color: isCompleted ? Colors.amber : Colors.white38, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(mission.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: isCompleted ? TextDecoration.lineThrough : null)),
                    Text("+${mission.xpReward} XP", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(mission.description, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: mission.progress,
                        backgroundColor: Colors.white10,
                        color: isCompleted ? Colors.green : Colors.blue,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isCompleted)
            const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
    );
  }
}
