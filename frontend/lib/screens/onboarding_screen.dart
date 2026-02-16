import 'package:flutter/material.dart';
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
      "title": "LA ISLA TE NECESITA",
      "desc": "Tenerife ha quedado oculta bajo la niebla. Tu misión es redescubrir cada rincón de nuestra tierra.",
      "icon": "🏝️"
    },
    {
      "title": "CONQUISTA TERRITORIOS",
      "desc": "Entra en los municipios para despejar la niebla. Cada lugar visitado ilumina el mapa oficial del Cabildo.",
      "icon": "🗺️"
    },
    {
      "title": "CAPTURA EL PATRIMONIO",
      "desc": "Saca fotos a los Bienes de Interés Cultural y comparte tus conquistas para convertirte en Leyenda.",
      "icon": "📸"
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _finish(),
                  child: const Text("SALTAR", style: TextStyle(color: Colors.grey)),
                ),
                Row(
                  children: List.generate(_pages.length, (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index ? Colors.green : Colors.grey[300],
                    ),
                  )),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _finish();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text(_currentPage == _pages.length - 1 ? "EMPEZAR" : "SIGUIENTE"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, String> page) {
    return Container(
      padding: const EdgeInsets.all(40),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(page['icon']!, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 40),
          Text(page['title']!, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          Text(page['desc']!, 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5)),
        ],
      ),
    );
  }

  void _finish() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainContainer()));
  }
}
