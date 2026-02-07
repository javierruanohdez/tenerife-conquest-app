import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/poi_provider.dart';
import '../models/poi.dart';

class CapturePreviewScreen extends StatelessWidget {
  final String imagePath;

  const CapturePreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<POIProvider>(context);
    final nearest = provider.nearestPoi;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Nueva Captura", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (nearest != null)
                  Text("Estás cerca de: ${nearest.name}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.location_on),
                  label: const Text("ASOCIAR A UBICACIÓN CERCANA"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: nearest == null ? null : () {
                    // Lógica para guardar en historial
                    provider.forceCheckIn(nearest);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("¡Foto asociada a ${nearest.name}!")),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.groups),
                  label: const Text("COMPARTIR CON GRUPOS"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    // Aquí llamaremos a la lógica de compartir que ya tenemos
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Compartiendo con tus grupos...")),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
