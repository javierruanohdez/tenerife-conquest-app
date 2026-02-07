import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/poi_provider.dart';

class ConquestScreen extends StatelessWidget {
  const ConquestScreen({super.key});

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

                  margin: const EdgeInsets.only(bottom: 16),

                  child: Column(

                    children: [

                      Image.network(

                        visit.photoUrl,

                        height: 180,

                        width: double.infinity,

                        fit: BoxFit.cover,

                        errorBuilder: (context, error, stackTrace) => Container(

                          height: 180,

                          color: Colors.green[100],

                          child: const Icon(Icons.photo, size: 50, color: Colors.green),

                        ),

                      ),

                      ListTile(

                        title: Text(visit.poi.name, style: const TextStyle(fontWeight: FontWeight.bold)),

                        subtitle: Text("Conquistado el: ${visit.date.day}/${visit.date.month}/${visit.date.year}"),

                        trailing: const Icon(Icons.verified, color: Colors.blue),

                      ),

                    ],

                  ),

                );

              },

            ),

      );

    }

  }

  