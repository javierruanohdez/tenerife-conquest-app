import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_container.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "category": "Estaciones meteorológicas",
      "title": "El clima también juega",
      "text": "Visita estaciones meteorológicas reales y consulta datos en tiempo real.\nAl encontrarlas desbloquearás información especial y recompensas relacionadas con el entorno natural.",
      "tip": "Tip: Algunas estaciones están en zonas de alta montaña. Planifica tu visita.",
      "icon": "🌡️"
    },
    {
      "category": "Puntos de interés",
      "title": "Descubre lugares únicos",
      "text": "Encuentra miradores, espacios naturales y rincones emblemáticos.\nCada punto de interés te aportará información, curiosidades y experiencia para avanzar.",
      "tip": "Tip: Explora el mapa para localizarlos todos.",
      "icon": "📸"
    },
    {
      "category": "Bienes de Interés Cultural",
      "title": "Viaja en el tiempo",
      "text": "Descubre edificios, tradiciones y lugares históricos reconocidos como Bienes de Interés Cultural.\nAprender también suma puntos y desbloquea recompensas especiales.",
      "tip": "Tip: Busca el icono del templo para encontrar tesoros históricos.",
      "icon": "🏛️"
    },
    {
      "category": "Grupos y Ranking",
      "title": "Compite y comparte",
      "text": "Únete a grupos de exploradores y compite por el primer puesto en el ranking.\n¡Conquista Tenerife junto a tus amigos!",
      "tip": "Tip: Pulsa el icono de mensaje en el mapa para ver el ranking.",
      "icon": "👥"
    },
    {
      "category": "Misiones Especiales",
      "title": "Supera retos épicos",
      "text": "Participa en eventos temporales y misiones temáticas.\nCompleta desafíos específicos para ganar artefactos legendarios y bonus de honor.",
      "tip": "Tip: Revisa la sección de misiones para ver los eventos activos.",
      "icon": "🎯"
    },
    {
      "category": "Niveles y recompensas",
      "title": "Sube de nivel",
      "text": "Cada visita, cada ruta completada y cada descubrimiento te da experiencia.\nSube de nivel, consigue insignias y desbloquea nuevas zonas y retos exclusivos.",
      "tip": "Tip: Revisa tu perfil para consultar tus logros.",
      "icon": "🏆"
    },
    {
      "category": "Tu misión",
      "title": "Explora, aprende y supera retos",
      "text": "Tu objetivo es descubrir Tenerife jugando.\nSupera desafíos, amplía tu conocimiento de la isla y conviértete en explorador avanzado.",
      "tip": "",
      "icon": "🧭"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (v) => setState(() => _currentPage = v),
            itemCount: _pages.length,
            itemBuilder: (context, i) => _buildPage(_pages[i]),
          ),
          Positioned(
            bottom: 50, left: 20, right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index ? Colors.green : Colors.grey[300],
                    ),
                  )),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? "Comenzar a explorar" : "SIGUIENTE",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                if (_currentPage < _pages.length - 1)
                  TextButton(
                    onPressed: () => _finish(),
                    child: const Text("SALTAR TUTORIAL", style: TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, String> page) {
    final isSpecial = page['category']!.contains("Grupos") || page['category']!.contains("Misiones");

    return Container(
      padding: const EdgeInsets.all(40),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono con efecto de "Coach Mark" para secciones especiales
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSpecial ? Colors.blue[50] : Colors.transparent,
              shape: BoxShape.circle,
              border: isSpecial ? Border.all(color: Colors.blue[200]!, width: 2) : null,
            ),
            child: Text(page['icon']!, style: const TextStyle(fontSize: 80)),
          ),
          const SizedBox(height: 20),
          Text(page['category']!.toUpperCase(), 
            style: TextStyle(color: isSpecial ? Colors.blue[800] : Colors.green[800], fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Text(page['title']!, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(page['text']!, 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5)),
          if (page['tip']!.isNotEmpty) ...[
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSpecial ? Colors.blue[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSpecial ? Colors.blue[200]! : Colors.orange[200]!)
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: isSpecial ? Colors.blue[900] : Colors.orange[900]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(page['tip']!, 
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: isSpecial ? Colors.blue[900] : Colors.orange[900], fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainContainer()));
    }
  }
}
