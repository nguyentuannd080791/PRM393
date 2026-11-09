import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main navigation shell hosting the 4 primary bottom tabs.
class AppBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppBottomNav({super.key, required this.navigationShell});

  void _onDestinationSelected(int index) {
    // Switching branch. If already on this branch, initialLocation resets it to the branch root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 72,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF0866FF)
                  : const Color(0xFF667085),
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFF0866FF)
                  : const Color(0xFF667085),
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: const Color(0xFFFFFFFF),
          indicatorColor: const Color(0xFFE6EEFF),
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          elevation: 3,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.search, color: Color(0xFF0866FF)),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Friends',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
