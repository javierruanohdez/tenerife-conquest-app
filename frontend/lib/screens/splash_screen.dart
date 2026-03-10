import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/poi_provider.dart';
import '../main_container.dart';
import 'onboarding_screen.dart'; // IMPORTAR ONBOARDING

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Iniciamos la carga de datos desde el provider
    await Provider.of<POIProvider>(context, listen: false).loadData();
    
    // Comprobar si es la primera vez
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    // Una pequeña pausa estética para que se vea el logo
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      if (onboardingCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainContainer()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[800]!, Colors.green[400]!],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.eco, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              "CONQUISTA\nTENERIFE",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
                        const Text(
                          "Cargando datos de la isla...",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const Spacer(),
                        // BARRA INSTITUCIONAL
                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/Flag_of_Europe.svg/255px-Flag_of_Europe.svg.png",
                                height: 40,
                              ),
                              const SizedBox(width: 20),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Solución Digital", style: TextStyle(color: Colors.white, fontSize: 10)),
                                  Text("Impulsada por los ODS", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(width: 30),
                              const Icon(Icons.account_balance, color: Colors.white, size: 30), // Placeholder Cabildo
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
            