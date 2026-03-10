import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Importante para los gráficos
import '../providers/poi_provider.dart';

class CabildoDashboardScreen extends StatelessWidget {
  const CabildoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<POIProvider>(context);
    final stats = provider.globalConquestStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Visión General", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Visión General de la Isla"),
            _buildGlobalConquestMap(provider),
            _buildSectionTitle("Métricas Clave"),
            _buildKeyMetrics(stats),
            _buildSectionTitle("Impacto y Seguridad"),
            _buildImpactMetrics(stats),
            _buildPreventionAnalysis(), // Nuevo gráfico de líneas
            _buildSectionTitle("Distribución de Intereses"),
            _buildPoiTypeDistribution(provider),
            _buildSectionTitle("Puntos de Alto Interés"),
            _buildTopPOIs(provider), // Nueva lista de sitios populares
            _buildSectionTitle("Reportes de la Comunidad"),
            _buildReportsSection(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
      ),
    );
  }

  Widget _buildGlobalConquestMap(POIProvider provider) {
    final discoveredMunis = provider.discoveredMunicipios; // Para la demo, usamos los del usuario
    final totalMunis = provider.borders.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Progreso de Conquista Comunitario", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
                Text("${discoveredMunis.length}/$totalMunis Menceyatos", style: TextStyle(fontSize: 14, color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(28.2916, -16.6291),
                    initialZoom: 9.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}{r}.png",
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.tnf_datos_app',
                    ),
                    PolygonLayer(
                      polygons: provider.borders.map((muni) {
                        final name = muni.name.toUpperCase().trim();
                        final isDiscovered = discoveredMunis.any(
                          (dm) => dm.toUpperCase().trim() == name
                        );
                        return muni.paths.map((path) => Polygon(
                          points: path,
                          color: isDiscovered ? Colors.teal.withOpacity(0.6) : Colors.blueGrey.withOpacity(0.4),
                          borderStrokeWidth: 1,
                          borderColor: isDiscovered ? Colors.teal[800]! : Colors.blueGrey[600]!,
                        ));
                      }).expand((i) => i).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _metricCard(Icons.location_on, "Total Conquistas", "${stats['totalConquistas'] ?? 0}", Colors.indigo),
          _metricCard(Icons.diamond, "Artefactos Encontrados", "${stats['totalArtefactos'] ?? 0}", Colors.deepOrange),
          _metricCard(Icons.warning, "Reportes Activos", "${stats['reportesAmbientales'] ?? 0}", Colors.red),
        ],
      ),
    );
  }

  Widget _buildImpactMetrics(Map<String, dynamic> stats) {
    final guayotaStats = stats['impactoGuayota'] ?? {};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _metricCard(Icons.local_fire_department, "Zonas Guayota Afectadas", "${guayotaStats['zonasAfectadas'] ?? 0}", Colors.redAccent),
          _metricCard(Icons.directions_walk, "Desvíos por Seguridad", "${guayotaStats['desviosExitosos'] ?? 0}", Colors.lightGreen),
        ],
      ),
    );
  }

  Widget _buildReportsSection(Map<String, dynamic> stats) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Reportes Recientes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
            const SizedBox(height: 10),
            // Esto sería dinámico de la BD en un entorno real
            _reportItem("Sendero Barranco Seco", "Basura excesiva", "2 días", Colors.orange),
            _reportItem("Mirador de Masca", "Cartel dañado", "1 semana", Colors.red),
            _reportItem("Playa de las Teresitas", "Alga invasora", "3 días", Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildPreventionAnalysis() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Efectividad de Alertas (Prevención)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text(['Lun', 'Mar', 'Mie', 'Jue', 'Vie'][v.toInt()], style: const TextStyle(fontSize: 10)))),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 12, color: Colors.redAccent)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 18, color: Colors.redAccent)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 5, color: Colors.redAccent)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 25, color: Colors.redAccent)]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 14, color: Colors.redAccent)]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Usuarios que evitaron zonas de calor extremo tras recibir alerta.", style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPOIs(POIProvider provider) {
    // Simulamos los sitios más visitados basados en la lista de POIs
    final topPois = provider.allPois.take(3).toList();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Column(
        children: topPois.map((p) => ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.workspace_premium, color: Colors.white, size: 18)),
          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(p.municipio, style: const TextStyle(fontSize: 12)),
          trailing: const Text("84 visitas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        )).toList(),
      ),
    );
  }

  Widget _metricCard(IconData icon, String title, String value, Color color) {
    return SizedBox(
      width: 160,
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color, width: 1)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportItem(String location, String issue, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.report_problem, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                Text(issue, style: TextStyle(color: Colors.blueGrey)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: Colors.blueGrey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPoiTypeDistribution(POIProvider provider) {
    Map<String, int> distribution = {};
    for (var v in provider.visits) {
      distribution[v.poi.type] = (distribution[v.poi.type] ?? 0) + 1;
    }

    if (distribution.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              "Sin datos de conquistas para analizar.",
              style: TextStyle(color: Colors.blueGrey[400], fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Distribución de Conquistas por Tipo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: distribution.keys.map((type) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: _getColorForType(type)),
                  const SizedBox(width: 4),
                  Text(type, style: TextStyle(fontSize: 12, color: Colors.blueGrey[700])),
                ],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    if (type.contains("Arquitectónico")) return Colors.indigo;
    if (type.contains("Natural")) return Colors.teal;
    if (type.contains("Recreativo")) return Colors.orange;
    if (type.contains("BIC")) return Colors.purple; // BICs son un tipo más cultural/histórico
    return Colors.blueGrey;
  }
}