import 'package:flutter/material.dart';
import '../components/navigation/navigation.dart';

/// App Layout - Layout wrapper untuk halaman utama dengan Bottom Navigation
///
/// Layout ini digunakan untuk 3 halaman utama:
/// - Home (index 0)
/// - Modul (index 1)
/// - Profile (index 2)
///
/// Halaman-halaman child/detail tidak menggunakan layout ini
class AppLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const AppLayout({super.key, required this.child, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => _handleNavigation(context, index),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    // Jangan navigate jika sudah di halaman yang sama
    if (index == currentIndex) return;

    // Navigate ke halaman yang sesuai
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/modul');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
}
