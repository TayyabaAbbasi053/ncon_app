import 'package:flutter/material.dart';
import '../utils/colors.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 1. The Container now acts as the "Sticker" base
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        border: const Border(
          top: BorderSide(color: AppColors.neonLime, width: 3), // Heavy top border
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.darkCharcoal, // Match the dark theme
        selectedItemColor: AppColors.neonLime,  // Pop color for active state
        unselectedItemColor: Colors.white54,    // Muted for inactive
        elevation: 0,                           // Remove standard shadow
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w900,         // Extra bold for Neobrutalism
          fontSize: 11,
          letterSpacing: 1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view), // Changed to look more "Grid/All"
            label: 'ALL',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'CARPOOL',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'MARKET',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'JOBS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'EVENTS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'NEWS',
          ),
        ],
      ),
    );
  }
}