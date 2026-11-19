import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class StreakTrackerWidget extends StatelessWidget {
  final int streakDays;

  const StreakTrackerWidget({
    super.key,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Mon, 7 = Sun
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.fireGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5C72).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$streakDays Days Streak',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 7-day strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayIndex = index + 1; // 1 to 7
              final isToday = dayIndex == currentWeekday;
              final isPastOrToday = dayIndex <= currentWeekday;

              return Column(
                children: [
                  Text(
                    dayNames[index],
                    style: TextStyle(
                      color: isToday
                          ? AppTheme.primaryGreen
                          : (isPastOrToday ? AppTheme.textSecondary : AppTheme.textTertiary),
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? AppTheme.primaryGreen.withValues(alpha: 0.16)
                          : (isPastOrToday
                              ? AppTheme.primaryGreenLight
                              : AppTheme.surfaceLight),
                      border: Border.all(
                        color: isToday
                            ? AppTheme.primaryGreen
                            : (isPastOrToday
                                ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                                : AppTheme.glassBorder),
                        width: isToday ? 1.8 : 1,
                      ),
                      boxShadow: isToday
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: -1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isPastOrToday
                          ? Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: isToday ? AppTheme.primaryGreen : AppTheme.primaryGreenDark,
                            )
                          : Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.textTertiary.withValues(alpha: 0.35),
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
