import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart'; // Import agregado
import 'package:latlong2/latlong.dart'; // Import agregado
import '../providers/poi_provider.dart';
import 'cabildo_dashboard_screen.dart'; // Importar la nueva pantalla

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
            _buildHeader(context, provider),
            const SizedBox(height: 20),
            _buildStatsRow(provider),
            const SizedBox(height: 20),
            _buildInventory(provider),
            const SizedBox(height: 20),
            _buildLegendaryBadges(provider),
            const SizedBox(height: 20),
            _buildMedalsRow(provider),
            const SizedBox(height: 20),
            _buildGlobalRankCard(provider),
            const SizedBox(height: 20),
            _buildConquestJournal(context, provider), // Nueva sección del diario
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

  Widget _buildLegendaryBadges(POIProvider provider) {
    final badges = provider.legendaryBadges;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("LOGROS DE LEYENDA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: badge.isUnlocked
                              ? Image.asset(badge.imagePath, fit: BoxFit.cover)
                              : ColorFiltered(
                                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                  child: Opacity(
                                    opacity: 0.5,
                                    child: Image.asset(badge.imagePath, fit: BoxFit.cover),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(badge.name, 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, fontWeight: badge.isUnlocked ? FontWeight.bold : FontWeight.normal, color: badge.isUnlocked ? Colors.black : Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventory(POIProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.backpack, color: Colors.brown[600], size: 16),
              const SizedBox(width: 8),
              const Text("BOLSA DE GUERRERO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4E1C1), // Color pergamino/piel curtida
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.brown.withAlpha(25), blurRadius: 4, offset: const Offset(0, 2)),
              ],
              border: Border.all(color: Colors.brown[300]!, width: 1.5),
            ),
            child: provider.inventory.isEmpty
                ? const Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: Colors.brown, size: 30),
                        SizedBox(height: 6),
                        Text("Tu bolsa está vacía.", 
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: Colors.brown, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: provider.inventory.length,
                    itemBuilder: (context, index) {
                      final item = provider.inventory[index];
                      return GestureDetector(
                        onTap: () => _showArtifactDetail(context, item),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.brown[900]!.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.brown[400]!.withOpacity(0.3)),
                          ),
                          child: Icon(item.icon, color: Colors.brown[800], size: 20),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showArtifactDetail(BuildContext context, Artifact item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDF5E6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.brown, width: 2)),
        title: Text(item.name.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 60, color: item.color),
            const SizedBox(height: 20),
            Text(item.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Divider(),
            const Text("Objeto de tu colección ancestral", style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CERRAR", style: TextStyle(color: Colors.brown))),
        ],
      ),
    );
  }

  Widget _buildMedalsRow(POIProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TÓTEMS DE PODER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.brown)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _medalIcon("Norte", provider.discoveredMunicipios.length > 10, Icons.landscape, Colors.green[800]!),
              _medalIcon("Sur", provider.discoveredMunicipios.length > 5, Icons.wb_sunny_rounded, Colors.orange[800]!),
              _medalIcon("Capital", provider.discoveredMunicipios.contains("SANTA CRUZ DE TENERIFE"), Icons.fort, Colors.blue[800]!),
              _medalIcon("Mencey", provider.discoveredMunicipios.length == 31, Icons.auto_awesome, Colors.amber[900]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _medalIcon(String label, bool active, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: active ? color : Colors.grey[300]!, width: 2),
            color: active ? color.withOpacity(0.1) : Colors.grey[100],
          ),
          child: Icon(icon, color: active ? color : Colors.grey[400], size: 28),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? Colors.brown[900] : Colors.grey)),
      ],
    );
  }

  Widget _buildUnlockedSecrets(POIProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SECRETOS ANCESTRALES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.brown)),
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

  Widget _buildHeader(BuildContext context, POIProvider provider) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.green[900]!, Colors.green[700]!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Center(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: provider.levelProgress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white24,
                    color: Colors.amber,
                  ),
                ),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 60, color: Colors.green),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.amber,
                    child: Text("${provider.level}", 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 48), // Spacer for centering
                Text(provider.userName, 
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                  onPressed: () => _editUserName(context, provider),
                ),
              ],
            ),
            Text(provider.levelName, 
              style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: provider.levelProgress,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  color: Colors.amber,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text("${(provider.levelProgress * 100).toInt()}% para el siguiente nivel", 
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _editUserName(BuildContext context, POIProvider provider) {
    final TextEditingController controller = TextEditingController(text: provider.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cambiar nombre de usuario"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nuevo nombre"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.updateUserName(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(POIProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.brown[200]!, width: 1)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("${provider.points}", "Honor de Guerrero"),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              _statItem("${provider.visits.length}", "Sitios Sagrados"),
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
          title: const Text("Ajustes de la app"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSettingsDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text("Acerca de Conquista Tenerife"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showAboutDialog(context);
          },
        ),
        // Botón oculto para el Dashboard del Cabildo (Admin)
        TextButton(
          onPressed: () {}, // Necesario para compilar, aunque la acción sea onLongPress
          onLongPress: () {
            _showAdminPasswordDialog(context);
          },
          child: const Text("V. Ancestral (Admin)", style: TextStyle(color: Colors.transparent)), // Texto invisible para el usuario normal
        ),
        const SizedBox(height: 40),
        _buildInstitutionalFooter(),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ajustes de la app", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text("Tema"),
              subtitle: const Text("Claro / Oscuro"),
              trailing: Switch(value: false, onChanged: (v) {}),
            ),
            ListTile(
              leading: const Icon(Icons.accessibility),
              title: const Text("Accesibilidad"),
              subtitle: const Text("Texto grande, alto contraste..."),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text("Idioma"),
              subtitle: const Text("Español (ES)"),
              onTap: () {},
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
        const Text("Proyecto desarrollado en alineación con los ODS", style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: "Conquista Tenerife",
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

  void _showAdminPasswordDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Acceso Restringido", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Introduce la clave de los Menceyes para acceder al Panel de Visión General."),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Clave de Acceso",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              if (controller.text == "MENCEY2026") {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CabildoDashboardScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Clave incorrecta.")),
                );
              }
            },
            child: const Text("Entrar"),
          ),
        ],
      ),
    );
  }

  Widget _buildConquestJournal(BuildContext context, POIProvider provider) {
    final discoveredMunis = provider.discoveredMunicipios;
    final totalMunis = provider.borders.length;
    final progress = totalMunis > 0 ? (discoveredMunis.length / totalMunis) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: Colors.brown[600], size: 18),
              const SizedBox(width: 8),
              const Text("DIARIO DE LAS HUELLAS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.brown)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF4E1C1),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.brown.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: Colors.brown[300]!, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tierra Conquistada", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 150,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(28.2916, -16.6291),
                              initialZoom: 9.0,
                              interactionOptions: InteractionOptions(
                                flags: InteractiveFlag.none, // Correcto: dentro de InteractionOptions y usando 'flags'
                              ),
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
                                  final isDiscovered = provider.discoveredMunicipios.any(
                                    (dm) => dm.toUpperCase().trim() == name
                                  );
                                  return muni.paths.map((path) => Polygon(
                                    points: path,
                                    color: isDiscovered ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.5),
                                    borderStrokeWidth: 1,
                                    borderColor: isDiscovered ? Colors.green[800]! : Colors.grey[600]!,
                                  ));
                                }).expand((i) => i).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text("${discoveredMunis.length}/$totalMunis", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
                        const Text("Menceyatos", style: TextStyle(fontSize: 12, color: Colors.brown)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 60,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                            color: Colors.green[700],
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 10, color: Colors.brown)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Recorrido", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _journalStatItem(Icons.nature_people, "Sitios", "${provider.visits.length}", Colors.green),
                    _journalStatItem(Icons.shield_outlined, "Artefactos", "${provider.inventory.length}", Colors.orange),
                    _journalStatItem(Icons.hiking, "Senderos", "${(provider.totalDistance / 1000).toStringAsFixed(1)} km", Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _journalStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.brown)),
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
