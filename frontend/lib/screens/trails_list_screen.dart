import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/poi_provider.dart';
import '../models/itinerary.dart';

class TrailsListScreen extends StatelessWidget {
  const TrailsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<POIProvider>(context);
    final trails = provider.itineraries;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explorar Senderos", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trails.length,
              itemBuilder: (context, index) {
                final trail = trails[index];
                return _buildTrailCard(context, trail, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: "Buscar por nombre o municipio...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildTrailCard(BuildContext context, Itinerary trail, POIProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          provider.setHighlightedItinerary(trail.matricula);
          // Navegar al mapa (index 0)
          // (Se gestiona en MainContainer)
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              color: Colors.orange[100],
              child: const Icon(Icons.terrain, size: 50, color: Colors.orange),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(trail.matricula, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      const Icon(Icons.star_border, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(trail.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(trail.description, 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.straighten, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${trail.distancia} m", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 16),
                      const Icon(Icons.trending_up, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text("+${trail.desnivelPos}m", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 16),
                      const Icon(Icons.speed, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(trail.clase, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
