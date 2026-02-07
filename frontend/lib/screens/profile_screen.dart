import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/poi_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<POIProvider>(context);
    final visits = provider.visits;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(provider),
            const SizedBox(height: 20),
            _buildStatsRow(provider),
            const SizedBox(height: 20),
            if (visits.isNotEmpty) _buildDataDashboard(provider),
            _buildMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(POIProvider provider) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: BoxDecoration(
        color: Colors.green[800],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Center(
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 60, color: Colors.green),
            ),
            const SizedBox(height: 16),
            const Text("Yone Explorador", 
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(provider.points > 500 ? "Guardián de la Isla" : "Eco-Viajero", 
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(POIProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("${provider.points}", "Eco-Puntos"),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              _statItem("${provider.visits.length}", "Conquistas"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataDashboard(POIProvider provider) {
    // Calculamos distribución por tipos de POI
    Map<String, int> distribution = {};
    for (var v in provider.visits) {
      distribution[v.poi.type] = (distribution[v.poi.type] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ANÁLISIS DE EXPLORACIÓN", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: distribution.entries.map((e) {
                      return PieChartSectionData(
                        color: _getColorForType(e.key),
                        value: e.value.toDouble(),
                        title: '${e.value}',
                        radius: 50,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: distribution.keys.map((type) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: _getColorForType(type)),
                    const SizedBox(width: 4),
                    Text(type, style: const TextStyle(fontSize: 12)),
                  ],
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    if (type.contains("Arquitectónico")) return Colors.blue;
    if (type.contains("Natural")) return Colors.green;
    if (type.contains("Recreativo")) return Colors.orange;
    return Colors.purple;
  }

  Widget _buildMenu(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text("Ajustes de la cuenta"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text("Ayuda y Soporte"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
