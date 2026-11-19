import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'animated_components.dart';

class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onScanTap;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      height: 74,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Glass Bar Container
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 66,
                decoration: BoxDecoration(
                  color: AppTheme.glassSurface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppTheme.glassBorder,
                    width: 1.2,
                  ),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.home_rounded,
                      activeIcon: Icons.home_rounded,
                      label: 'Dashboard',
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.history_rounded,
                      activeIcon: Icons.history_rounded,
                      label: 'History',
                    ),
                    const SizedBox(width: 56), // Space for floating animated button
                    _buildNavItem(
                      index: 2,
                      icon: Icons.insights_rounded,
                      activeIcon: Icons.insights_rounded,
                      label: 'Analytics',
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.person_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Center Scan Button with Pulsing Breathing Glow & Spring Feedback
          Positioned(
            top: -14,
            child: PulsingGlow(
              glowColor: AppTheme.primaryGreen,
              minSpread: 1.0,
              maxSpread: 6.0,
              minBlur: 14.0,
              maxBlur: 26.0,
              duration: const Duration(milliseconds: 2000),
              isCircle: true,
              child: BouncingWidget(
                onTap: onScanTap,
                scaleFactor: 0.90,
                duration: const Duration(milliseconds: 140),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    border: Border.all(
                      color: AppTheme.cardBackground,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: AppTheme.textOnPrimary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return BouncingWidget(
      onTap: () => onTap(index),
      scaleFactor: 0.92,
      duration: const Duration(milliseconds: 120),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textTertiary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
