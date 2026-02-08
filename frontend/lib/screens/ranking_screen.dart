import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/poi_provider.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<POIProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tenerife Rankings", style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _showScanner(context),
              tooltip: "Unirse a grupo",
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Global"),
              Tab(text: "Mi Grupo"),
            ],
            indicatorColor: Colors.green,
            labelColor: Colors.green,
          ),
        ),
        body: TabBarView(
          children: [
            _buildRankingList(provider.globalRanking),
            _buildGroupView(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupView(BuildContext context, POIProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.green[50],
            child: ListTile(
              title: const Text("Grupo: Exploradores ULPGC", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Toca para ver el QR del grupo"),
              trailing: const Icon(Icons.qr_code),
              onTap: () => _showGroupQR(context),
            ),
          ),
        ),
        Expanded(child: _buildRankingList(provider.groupRanking)),
      ],
    );
  }

  Widget _buildRankingList(List<Explorer> explorers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: explorers.length,
      itemBuilder: (context, index) {
        final ex = explorers[index];
        return Card(
          color: ex.isMe ? Colors.green[50] : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(index),
              child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(ex.name, style: TextStyle(fontWeight: ex.isMe ? FontWeight.bold : FontWeight.normal)),
            subtitle: const Text("Tenerife Explorer"),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("${ex.conquests}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                const Text("Sitios", style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return Colors.amber; // Oro
    if (index == 1) return Colors.grey[400]!; // Plata
    if (index == 2) return Colors.brown[300]!; // Bronce
    return Colors.green[700]!;
  }

  void _showScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              debugPrint('Grupo encontrado: ${barcode.rawValue}');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Unido al grupo: ${barcode.rawValue}")),
              );
            }
          },
        ),
      ),
    );
  }

  void _showGroupQR(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Código QR del Grupo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enseña este código a tus amigos para que se unan al grupo."),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: "Exploradores_ULPGC_2026",
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
        ],
      ),
    );
  }
}