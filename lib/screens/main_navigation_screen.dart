import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'episode_screen.dart';
import 'favorite_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deadRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(90, 40),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda telah berhasil keluar.'),
          backgroundColor: AppTheme.portalTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      FavoriteScreen(
        onExploreTap: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      const EpisodeScreen(),
    ];

    final titles = [
      'Rick & Morty Characters',
      'Favorite Characters',
      'Episodes',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.deadRed),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_alt_rounded),
            label: 'Characters',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline_rounded),
            activeIcon: Icon(Icons.favorite_rounded),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tv_outlined),
            activeIcon: Icon(Icons.tv_rounded),
            label: 'Episodes',
          ),
        ],
      ),
    );
  }
}

