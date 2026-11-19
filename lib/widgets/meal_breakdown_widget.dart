import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/food_models.dart';

class MealBreakdownWidget extends StatelessWidget {
  final List<LoggedFoodEntry> entries;
  final Function(String mealType) onAddMeal;

  const MealBreakdownWidget({
    super.key,
    required this.entries,
    required this.onAddMeal,
  });

  @override
  Widget build(BuildContext context) {
    final mealSlots = [
      {'name': 'Breakfast', 'icon': Icons.wb_twilight_rounded, 'color': AppTheme.macroCarbs},
      {'name': 'Lunch', 'icon': Icons.wb_sunny_rounded, 'color': AppTheme.primaryGreen},
      {'name': 'Dinner', 'icon': Icons.nightlight_round, 'color': AppTheme.macroProtein},
      {'name': 'Snacks', 'icon': Icons.apple_rounded, 'color': AppTheme.macroFat},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...mealSlots.map((slot) {
          final mealName = slot['name'] as String;
          final icon = slot['icon'] as IconData;
          final color = slot['color'] as Color;

          final mealEntries = entries.where((e) {
            return (e.mealType ?? 'Snack').toLowerCase() == mealName.toLowerCase();
          }).toList();

          final totalCals = mealEntries.fold<double>(
            0.0,
            (sum, e) => sum + e.parsedNutrition.calories,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildMealCard(
              context: context,
              mealName: mealName,
              icon: icon,
              color: color,
              entries: mealEntries,
              totalCalories: totalCals,
              onAdd: () => onAddMeal(mealName),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMealCard({
    required BuildContext context,
    required String mealName,
    required IconData icon,
    required Color color,
    required List<LoggedFoodEntry> entries,
    required double totalCalories,
    required VoidCallback onAdd,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealName,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalCalories > 0
                            ? '${totalCalories.toInt()} kcal • ${entries.length} ${entries.length == 1 ? 'item' : 'items'}'
                            : 'No food logged yet',
                        style: TextStyle(
                          color: totalCalories > 0 ? color : AppTheme.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Add button
              IconButton(
                onPressed: onAdd,
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: AppTheme.textPrimary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          // Logged Food Item Pills
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: 8),
            ...entries.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.scanData.foodName,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.parsedNutrition.calories.toInt()} kcal',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
