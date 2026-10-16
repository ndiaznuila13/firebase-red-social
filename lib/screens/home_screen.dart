import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'upload_screen.dart';

class HomeScreen extends StatefulWidget {
  final User usuario;

  const HomeScreen({super.key, required this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _irASubir() {
    setState(() => _currentIndex = 1);
  }

  void _volverAFeed() {
    setState(() => _currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      FeedScreen(
        usuario: widget.usuario,
        onIrASubir: _irASubir,
      ),
      UploadScreen(
        usuario: widget.usuario,
        onVideoSubido: _volverAFeed,
      ),
      ProfileScreen(
        usuario: widget.usuario,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Colors.white12, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_filled,
              label: 'Inicio',
            ),
            _buildUploadButton(),
            _buildNavItem(
              index: 2,
              icon: Icons.person_rounded,
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            color: isSelected ? Colors.white : Colors.white54,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _irASubir,
      child: SizedBox(
        width: 45,
        height: 30,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: Container(
                width: 38,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF20D5EC),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                width: 38,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2B54),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 38,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
