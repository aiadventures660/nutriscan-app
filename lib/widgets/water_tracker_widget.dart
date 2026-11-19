import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'animated_components.dart';

class WaterTrackerWidget extends StatelessWidget {
  final int currentMl;
  final int targetMl;
  final Function(int) onAddWater;
  final VoidCallback onResetWater;

  const WaterTrackerWidget({
    super.key,
    required this.currentMl,
    required this.targetMl,
    required this.onAddWater,
    required this.onResetWater,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentMl / targetMl).clamp(0.0, 1.0);
    final pct = (progress * 100).toInt();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.macroProtein.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.macroProtein.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: AppTheme.macroProtein,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hydration Tracker',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          AnimatedCountText(
                            value: currentMl.toDouble(),
                            suffix: ' ml',
                            style: TextStyle(
                              color: AppTheme.macroProtein,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            ' / $targetMl ml ($pct%)',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Quick Add Buttons with Bouncy Feedback
              Row(
                children: [
                  BouncingWidget(
                    onTap: () => onAddWater(250),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D2FF), Color(0xFF0091FF)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.macroProtein.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: Colors.black, size: 15),
                          SizedBox(width: 2),
                          Text(
                            '250ml',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  BouncingWidget(
                    onTap: () => onAddWater(500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.macroProtein.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.macroProtein.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: AppTheme.macroProtein, size: 15),
                          const SizedBox(width: 2),
                          Text(
                            '500ml',
                            style: TextStyle(
                              color: AppTheme.macroProtein,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Animated Liquid Wave Progress Bar
          WaveLiquidWidget(
            progress: progress,
            height: 12,
            primaryColor: const Color(0xFF00D2FF),
            waveColor: const Color(0xFF00F59B),
          ),
        ],
      ),
    );
  }
}
