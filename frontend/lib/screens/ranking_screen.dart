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
        backgroundColor: const Color(0xFFFDF5E6), // Color pergamino/tierra clara
        appBar: AppBar(
          title: const Text("CONSEJO DE MENCEYES", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
          backgroundColor: Colors.brown[800],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: () => _showScanner(context),
              tooltip: "Unirse a una Tribu",
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Isla Completa", icon: Icon(Icons.public)),
              Tab(text: "Mi Tribu", icon: Icon(Icons.shield)),
            ],
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
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
            color: Colors.brown[100],
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.brown[400]!, width: 2)),
            child: ListTile(
              leading: Icon(Icons.terrain, color: Colors.brown[800], size: 40),
              title: const Text("Tribu: Menceyato de Anaga", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: const Text("Toca para mostrar el Tótem de la tribu"),
              trailing: const Icon(Icons.qr_code_2),
              onTap: () => _showGroupQR(context),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: Divider(thickness: 2)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("GUERREROS DE LA TRIBU", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
              ),
              Expanded(child: Divider(thickness: 2)),
            ],
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
          elevation: ex.isMe ? 8 : 2,
          color: ex.isMe ? Colors.amber[100] : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: ex.isMe ? BorderSide(color: Colors.amber[800]!, width: 2) : BorderSide.none,
          ),
          child: ListTile(
            leading: _buildRankBadge(index),
            title: Text(ex.name, style: TextStyle(fontWeight: ex.isMe ? FontWeight.bold : FontWeight.bold, fontSize: 16, color: Colors.brown[900])),
            subtitle: Text(index < 3 ? "Guerrero de Élite" : "Cazador", style: TextStyle(color: Colors.brown[400])),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("${ex.conquests}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown[800])),
                const Text("LOGROS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(int index) {
    if (index == 0) return const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.workspace_premium, color: Colors.white));
    if (index == 1) return CircleAvatar(backgroundColor: Colors.grey[400], child: const Icon(Icons.workspace_premium, color: Colors.white));
    if (index == 2) return CircleAvatar(backgroundColor: Colors.orange[300], child: const Icon(Icons.workspace_premium, color: Colors.white));
    return CircleAvatar(
      backgroundColor: Colors.brown[200],
      child: Text("${index + 1}", style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
    );
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