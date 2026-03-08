import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'screens/map_screen.dart';
import 'screens/conquest_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/missions_screen.dart';
import 'screens/capture_preview_screen.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _getAdjustedIndex(),
        children: [
          MapScreen(),
          const MissionsScreen(),
          const ConquestScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) { 
            _showCameraAction(context);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: "Mapa",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: "Misiones",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera, size: 35, color: Colors.green),
            label: "Captura",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: "Conquista",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Usuario",
          ),
        ],
      ),
    );
  }

  int _getAdjustedIndex() {
    if (_currentIndex == 0) return 0; // Mapa
    if (_currentIndex == 1) return 1; // Grupos (Ranking)
    if (_currentIndex == 3) return 2; // Conquista
    if (_currentIndex == 4) return 3; // Usuario
    return 0;
  }

  void _showCameraAction(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => CapturePreviewScreen(imagePath: photo.path)));
      }
    } catch (e) {}
  }
}