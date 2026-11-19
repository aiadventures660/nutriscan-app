import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/user_models.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final double? progress;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.unit = '',
    required this.icon,
    this.color,
    this.subtitle,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryGreen;
    
    return AppCard(
      onTap: onTap,
      withGradient: true,
      padding: const EdgeInsets.all(AppTheme.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingXS),
                decoration: BoxDecoration(
                  color: effectiveColor.withOpacity(0.2),
                  borderRadius: AppTheme.smallRadius,
                ),
                child: Icon(
                  icon,
                  color: effectiveColor,
                  size: 16,
                ),
              ),
              const Spacer(),
              if (progress != null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: progress! / 100,
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                    backgroundColor: effectiveColor.withOpacity(0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: effectiveColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    unit,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: effectiveColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class ProgressCard extends StatelessWidget {
  final String title;
  final double progress;
  final String progressText;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  const ProgressCard({
    super.key,
    required this.title,
    required this.progress,
    required this.progressText,
    this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryGreen;
    
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: effectiveColor, size: 20),
                const SizedBox(width: AppTheme.spacingS),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                progressText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: AppTheme.surfaceAccent,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = goal.isCompleted;
    final progress = goal.progressPercentage;
    final daysLeft = goal.daysRemaining;
    
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? AppTheme.success.withOpacity(0.2)
                      : AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: AppTheme.smallRadius,
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : _getGoalIcon(goal.type),
                  color: isCompleted ? AppTheme.success : AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  color: AppTheme.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            goal.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            goal.description,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: AppTheme.surfaceAccent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? AppTheme.success : AppTheme.primaryGreen,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                '${progress.toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isCompleted ? AppTheme.success : AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.currentValue.toInt()} / ${goal.targetValue.toInt()} ${goal.unit}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (!isCompleted)
                Text(
                  daysLeft > 0 ? '$daysLeft days left' : 'Overdue',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: daysLeft > 0 ? AppTheme.textSecondary : AppTheme.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getGoalIcon(GoalType type) {
    switch (type) {
      case GoalType.dailyCalories:
        return Icons.local_fire_department;
      case GoalType.dailyProtein:
        return Icons.fitness_center;
      case GoalType.dailyCarbs:
        return Icons.grain;
      case GoalType.dailyFat:
        return Icons.opacity;
      case GoalType.weeklyScans:
        return Icons.camera_alt;
      case GoalType.waterIntake:
        return Icons.water_drop;
      case GoalType.exercise:
        return Icons.directions_run;
      case GoalType.weightLoss:
      case GoalType.weightGain:
        return Icons.monitor_weight;
      default:
        return Icons.flag;
    }
  }
}

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getAchievementIcon(achievement.iconName),
              color: AppTheme.textOnPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingS,
                  vertical: AppTheme.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: AppTheme.smallRadius,
                ),
                child: Text(
                  '${achievement.points} pts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                _formatDate(achievement.unlockedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'star':
        return Icons.star;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'restaurant':
        return Icons.restaurant;
      case 'schedule':
        return Icons.schedule;
      default:
        return Icons.emoji_events;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference}d ago';
    if (difference < 30) return '${(difference / 7).floor()}w ago';
    return '${(difference / 30).floor()}m ago';
  }
}

class NutritionChart extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? targetCalories;
  final double? targetProtein;
  final double? targetCarbs;
  final double? targetFat;

  const NutritionChart({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.targetCalories,
    this.targetProtein,
    this.targetCarbs,
    this.targetFat,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Nutrition',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildNutrientBar(
            context,
            'Calories',
            calories,
            targetCalories ?? 2000,
            'kcal',
            AppTheme.primaryGreen,
          ),
          const SizedBox(height: AppTheme.spacingS),
          _buildNutrientBar(
            context,
            'Protein',
            protein,
            targetProtein ?? 150,
            'g',
            Colors.blue,
          ),
          const SizedBox(height: AppTheme.spacingS),
          _buildNutrientBar(
            context,
            'Carbs',
            carbs,
            targetCarbs ?? 250,
            'g',
            Colors.orange,
          ),
          const SizedBox(height: AppTheme.spacingS),
          _buildNutrientBar(
            context,
            'Fat',
            fat,
            targetFat ?? 65,
            'g',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientBar(
    BuildContext context,
    String label,
    double current,
    double target,
    String unit,
    Color color,
  ) {
    final progress = target > 0 ? (current / target * 100).clamp(0, 100) : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${current.toInt()}/${target.toInt()} $unit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXS),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: AppTheme.surfaceAccent,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const QuickActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryGreen;
    
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingS),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: effectiveColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: effectiveColor,
              size: 20,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
