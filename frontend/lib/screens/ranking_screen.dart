import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          bottom: const TabBar(
            tabs: [
              Tab(text: "Global"),
              Tab(text: "Mi Grupo (Exploradores ULPGC)"),
            ],
            indicatorColor: Colors.green,
            labelColor: Colors.green,
          ),
        ),
        body: TabBarView(
          children: [
            _buildRankingList(provider.globalRanking),
            _buildRankingList(provider.groupRanking),
          ],
        ),
      ),
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
}
