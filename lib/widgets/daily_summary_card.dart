import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final today = DateTime.now();
        final summary = provider.getDailyNutritionSummary(today);
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF38e07b).withOpacity(0.1),
                const Color(0xFF38e07b).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF38e07b).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38e07b).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDate(today),
                      style: const TextStyle(
                        color: Color(0xFF38e07b),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      label: 'Calories',
                      value: '${summary['calories']?.round() ?? 0}',
                      unit: 'kcal',
                      color: Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _SummaryItem(
                      label: 'Protein',
                      value: '${summary['protein']?.round() ?? 0}',
                      unit: 'g',
                      color: Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _SummaryItem(
                      label: 'Carbs',
                      value: '${summary['carbs']?.round() ?? 0}',
                      unit: 'g',
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _SummaryItem(
                      label: 'Fat',
                      value: '${summary['fat']?.round() ?? 0}',
                      unit: 'g',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForLabel(label),
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'calories':
        return Icons.local_fire_department;
      case 'protein':
        return Icons.fitness_center;
      case 'carbs':
        return Icons.grain;
      case 'fat':
        return Icons.opacity;
      default:
        return Icons.circle;
    }
  }
}
