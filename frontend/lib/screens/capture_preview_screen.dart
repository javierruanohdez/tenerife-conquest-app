import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/poi_provider.dart';
import '../models/poi.dart';

class CapturePreviewScreen extends StatefulWidget {
  final String imagePath;

  const CapturePreviewScreen({super.key, required this.imagePath});

  @override
  State<CapturePreviewScreen> createState() => _CapturePreviewScreenState();
}

class _CapturePreviewScreenState extends State<CapturePreviewScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareWithGroups(POI? nearest) async {
    setState(() => _isSharing = true);
    
    try {
      // Creamos el widget estilo "Flow" para compartir
      final sharedWidget = _buildShareableCard(nearest);
      
      final image = await _screenshotController.captureFromWidget(
        sharedWidget,
        delay: const Duration(milliseconds: 200),
        context: context,
      );

      final directory = await getApplicationDocumentsDirectory();
      final imageFile = await File('${directory.path}/temp_share.png').create();
      await imageFile.writeAsBytes(image);

      final text = nearest != null 
        ? '¡Explorando ${nearest.name} en #ConquistaTenerife! 🌿' 
        : '¡Explorando Tenerife con #ConquistaTenerife! 🌿';

      await Share.shareXFiles([XFile(imageFile.path)], text: text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al compartir: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Widget _buildShareableCard(POI? nearest) {
    return Container(
      width: 400,
      height: 600,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TENERIFE", style: TextStyle(color: Colors.white, letterSpacing: 5, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("QUEST", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 22)),
                ],
              ),
              Icon(Icons.explore, color: Colors.white, size: 40),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 20),
          Text(nearest?.name.toUpperCase() ?? "TENERIFE", 
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(30)),
            child: const Text("CAPTURA TENERIFE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: FileImage(File(widget.imagePath)),
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
                        provider.forceCheckIn(nearest, customPhotoPath: widget.imagePath);
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
                      onPressed: _isSharing ? null : () => _shareWithGroups(nearest),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
          if (_isSharing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 20),
                    Text("Generando Captura Tenerife...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}