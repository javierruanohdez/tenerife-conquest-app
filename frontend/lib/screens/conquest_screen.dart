import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/poi_provider.dart';



import 'package:screenshot/screenshot.dart';

import 'package:share_plus/share_plus.dart';

import 'package:path_provider/path_provider.dart';

import 'dart:io';




class ConquestScreen extends StatefulWidget {

  const ConquestScreen({super.key});



  @override

  State<ConquestScreen> createState() => _ConquestScreenState();

}



class _ConquestScreenState extends State<ConquestScreen> {

  final ScreenshotController _screenshotController = ScreenshotController();



  Future<void> _shareConquest(Visit visit) async {

    // Creamos el widget que se va a capturar (fuera de la vista)

    final sharedWidget = _buildShareableCard(visit);

    

    final image = await _screenshotController.captureFromWidget(

      sharedWidget,

      delay: const Duration(milliseconds: 100),

      context: context,

    );



    final directory = await getApplicationDocumentsDirectory();

    final imagePath = await File('${directory.path}/conquest_${visit.poi.id}.png').create();

        await imagePath.writeAsBytes(image);

    

        await Share.shareXFiles([XFile(imagePath.path)], text: '¡Acabo de visitar ${visit.poi.name} con #ConquistaTenerife! 🌿🎮');

      }

    

      Widget _buildShareableCard(Visit visit) {

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

              Row(

                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [

                  const Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text("CONQUISTA", style: TextStyle(color: Colors.white, letterSpacing: 5, fontWeight: FontWeight.bold)),

                      Text("TENERIFE", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 22)),

                    ],

                  ),

    

              Text("${visit.date.day}/${visit.date.month}", style: const TextStyle(color: Colors.white70)),

            ],

          ),

          const SizedBox(height: 30),

          Expanded(

            child: ClipRRect(

              borderRadius: BorderRadius.circular(20),

              child: Image.network(visit.photoUrl, fit: BoxFit.cover),

            ),

          ),

          const SizedBox(height: 20),

          Text(visit.poi.name.toUpperCase(), 

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

    final visits = provider.visits;



    return Scaffold(

      appBar: AppBar(title: const Text("Mis Conquistas", style: TextStyle(fontWeight: FontWeight.bold))),

      body: visits.isEmpty 

        ? const Center(

            child: Text(

              "Aún no has conquistado ningún lugar.\n¡Sal a explorar Tenerife!", 

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 16),

            ),

          )

        : ListView.builder(

            padding: const EdgeInsets.all(16),

            itemCount: visits.length,

            itemBuilder: (context, index) {

              final visit = visits[index];

              return Card(

                clipBehavior: Clip.antiAlias,

                margin: const EdgeInsets.only(bottom: 20),

                child: Column(

                  children: [

                                        Stack(

                                          children: [

                                            visit.photoUrl.startsWith("http") 

                                              ? Image.network(

                                                  visit.photoUrl,

                                                  height: 220,

                                                  width: double.infinity,

                                                  fit: BoxFit.cover,

                                                )

                                              : Image.file(

                                                  File(visit.photoUrl),

                                                  height: 220,

                                                  width: double.infinity,

                                                  fit: BoxFit.cover,

                                                ),

                                            Positioned(

                    

                          top: 10, right: 10,

                          child: IconButton.filled(

                            icon: const Icon(Icons.share, color: Colors.white),

                            onPressed: () => _shareConquest(visit),

                            style: IconButton.styleFrom(backgroundColor: Colors.black54),

                          ),

                        ),

                      ],

                    ),

                    ListTile(

                      title: Text(visit.poi.name, style: const TextStyle(fontWeight: FontWeight.bold)),

                      subtitle: Text("Visitado el: ${visit.date.day}/${visit.date.month}/${visit.date.year}"),

                      trailing: const Icon(Icons.verified, color: Colors.blue, size: 30),

                    ),

                  ],

                ),

              );

            },

          ),

    );

  }

}



  