import 'package:flutter/material.dart';
import '../models/food_models.dart';

class VitaminMineralCard extends StatelessWidget {
  final VitaminMineral vitaminMineral;

  const VitaminMineralCard({
    super.key,
    required this.vitaminMineral,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              vitaminMineral.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              vitaminMineral.amount,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getDailyValueColor(vitaminMineral.dailyValue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                vitaminMineral.dailyValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDailyValueColor(String dailyValue) {
    // Extract percentage from string
    final regex = RegExp(r'(\d+)%');
    final match = regex.firstMatch(dailyValue);
    
    if (match != null) {
      final percentage = int.tryParse(match.group(1) ?? '0') ?? 0;
      
      if (percentage >= 50) {
        return Colors.green.withOpacity(0.3);
      } else if (percentage >= 25) {
        return Colors.orange.withOpacity(0.3);
      } else {
        return Colors.red.withOpacity(0.3);
      }
    }
    
    return Colors.grey.withOpacity(0.3);
  }
}
