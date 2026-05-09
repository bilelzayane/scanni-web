import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CustomGlassNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;

  const CustomGlassNavbar({
    super.key,
    required this.currentIndex,
    required this.onIndexSelected,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                // REMPLACEMENT : Utilisation du vert du logo avec opacité
                color: AppTheme.primaryColor.withOpacity(0.5),
                width: 1.5, // Légèrement plus épais pour bien voir le vert
              ),
              // OPTIONNEL : Un très léger halo vert pour accentuer l'effet
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.house_outlined,
                  isActive: currentIndex == 0,
                  onTap: () => onIndexSelected(0),
                ),
                _ScanButton(onTap: () => onIndexSelected(1)),
                _NavItem(
                  icon: Icons.history,
                  isActive: currentIndex == 2,
                  onTap: () => onIndexSelected(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: isActive
              ? AppTheme.primaryDarkColor
              : AppTheme.mutedForegroundColor,
          size: isActive ? 26 : 24,
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: AppTheme.softShadow,
        ),
        child: const Center(
          child: Icon(Icons.center_focus_strong, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
