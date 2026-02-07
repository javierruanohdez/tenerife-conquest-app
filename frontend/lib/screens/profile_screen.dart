import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/poi_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<POIProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
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
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem("${provider.points}", "Eco-Puntos"),
                _statItem("${provider.discoveredPoiIds.length}", "Conquistas"),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                const ListTile(
                  leading: Icon(Icons.settings),
                  title: Text("Ajustes de la cuenta"),
                  trailing: Icon(Icons.chevron_right),
                ),
                const ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text("Ayuda y Soporte"),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
