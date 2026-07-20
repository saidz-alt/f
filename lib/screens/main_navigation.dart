import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'shop_screen.dart';

/// The app's four-tab shell: Home, Progress, Shop, Profile.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    ProgressScreen(),
    ShopScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps each tab's scroll position/state alive when
      // switching, which matters once the Stage 2 path screen has state.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryGreen.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: AppColors.primaryGreen),
            label: context.t.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon:
                const Icon(Icons.bar_chart, color: AppColors.primaryGreen),
            label: context.t.navProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon:
                const Icon(Icons.storefront, color: AppColors.primaryGreen),
            label: context.t.navShop,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon:
                const Icon(Icons.person, color: AppColors.primaryGreen),
            label: context.t.navProfile,
          ),
        ],
      ),
    );
  }
}
