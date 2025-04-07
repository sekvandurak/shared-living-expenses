import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: NavigationBar(
          height: 70,
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          animationDuration: const Duration(milliseconds: 400),
          destinations: [
            _buildNavDestination(
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              label: 'Friends',
              isSelected: currentIndex == 0,
              colorScheme: colorScheme,
            ),
            _buildNavDestination(
              icon: Icons.group_outlined,
              selectedIcon: Icons.group,
              label: 'Groups',
              isSelected: currentIndex == 1,
              colorScheme: colorScheme,
            ),
            _buildNavDestination(
              icon: Icons.add_circle_outline,
              selectedIcon: Icons.add_circle,
              label: 'New Group',
              isSelected: currentIndex == 2,
              colorScheme: colorScheme,
            ),
            _buildNavDestination(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
              isSelected: currentIndex == 3,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required ColorScheme colorScheme,
  }) {
    return NavigationDestination(
      icon: Icon(
        icon,
        color: isSelected ? null : colorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedIcon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          selectedIcon,
          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
      label: label,
    );
  }
} 