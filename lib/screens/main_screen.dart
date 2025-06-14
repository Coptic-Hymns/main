import 'package:flutter/material.dart';
import 'hymns_screen.dart';
import 'prayers_screen.dart';
import 'saints_screen.dart';
import 'feasts_screen.dart';
import 'favorites_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HymnsScreen(),
    const PrayersScreen(),
    const SaintsScreen(),
    const FeastsScreen(),
    const FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(icon: Icon(Icons.music_note), label: 'Hymns'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Prayers'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Saints'),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Feasts',
          ),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'),
        ],
      ),
    );
  }
}
