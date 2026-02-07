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
            _buildMedalsRow(provider),
            const SizedBox(height: 20),
            _buildGlobalRankCard(provider),
            const SizedBox(height: 20),
            _buildUnlockedSecrets(provider),
            const SizedBox(height: 20),
            if (visits.isNotEmpty) _buildDataDashboard(provider),
            _buildMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMedalsRow(POIProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("MEDALLAS DE REGIÓN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _medalIcon("Norte", provider.discoveredMunicipios.length > 10, Icons.terrain, Colors.blue),
              _medalIcon("Sur", provider.discoveredMunicipios.length > 5, Icons.wb_sunny, Colors.orange),
              _medalIcon("Capital", provider.discoveredMunicipios.contains("SANTA CRUZ DE TENERIFE"), Icons.location_city, Colors.purple),
              _medalIcon("Leyenda", provider.discoveredMunicipios.length == 31, Icons.auto_awesome, Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _medalIcon(String label, bool active, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: active ? color.withOpacity(0.2) : Colors.grey[200],
          child: Icon(icon, color: active ? color : Colors.grey[400]),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.black87 : Colors.grey)),
      ],
    );
  }

  Widget _buildUnlockedSecrets(POIProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DIARIO DE SECRETOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          if (provider.discoveredMunicipios.isEmpty)
            const Text("Explora municipios para desbloquear sus secretos...", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
          ...provider.discoveredMunicipios.take(3).map((muni) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.auto_stories, color: Colors.green),
              title: Text(muni, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text("Secreto desbloqueado. ¡Luz recuperada!", style: TextStyle(fontSize: 12)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGlobalRankCard(POIProvider provider) {
    final ranking = provider.globalRanking;
    final myPos = ranking.indexWhere((e) => e.isMe) + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        color: Colors.amber[50],
        child: ListTile(
          leading: const Icon(Icons.stars, color: Colors.amber),
          title: const Text("Posición Global", style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text("#$myPos", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
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
          leading: const Icon(Icons.info_outline),
          title: const Text("Acerca de Tenerife Quest"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showAboutDialog(context);
          },
        ),
        const SizedBox(height: 40),
        _buildInstitutionalFooter(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInstitutionalFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/Flag_of_Europe.svg/255px-Flag_of_Europe.svg.png",
              height: 30,
            ),
            const SizedBox(width: 15),
            const Text("UNIÓN EUROPEA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 10),
        const Text("Proyecto cofinanciado por el Fondo FEDER", style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: "Tenerife Quest",
      applicationVersion: "5.0.0",
      applicationIcon: const Icon(Icons.explore, size: 50, color: Colors.green),
      children: [
        const SizedBox(height: 20),
        const Text("Desarrollado por:", style: TextStyle(fontWeight: FontWeight.bold)),
        const Text("- Yone Suárez"),
        const Text("- Lucas Mendoza"),
        const Text("- Javier Ruano"),
        const SizedBox(height: 20),
        const Text("Proyecto de Ingeniería de Datos (ULPGC) para el II Concurso de Datos Abiertos del Cabildo de Tenerife."),
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
