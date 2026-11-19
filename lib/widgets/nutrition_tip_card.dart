import 'package:flutter/material.dart';
import '../models/food_models.dart';
import 'report_content_button.dart';

class NutritionTipCard extends StatelessWidget {
  final NutritionTip tip;
  final VoidCallback onTap;

  const NutritionTipCard({
    super.key,
    required this.tip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom nutrition header instead of image
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        _getCategoryColor(tip.category).withOpacity(0.3),
                        _getCategoryColor(tip.category).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getCategoryIcon(tip.category),
                          color: _getCategoryColor(tip.category),
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(tip.category).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tip.category.toUpperCase(),
                            style: TextStyle(
                              color: _getCategoryColor(tip.category),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        tip.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Description
                      Text(
                        tip.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // AI disclaimer and actions row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Colors.blue,
                                  size: 10,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Read more',
                            style: TextStyle(
                              color: Color(0xFF38e07b),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            color: Color(0xFF38e07b),
                            size: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Report button positioned in top-right corner
            Positioned(
              top: 4,
              right: 4,
              child: ReportContentButton(
                contentId: tip.id,
                contentType: 'nutrition_tip',
                contentTitle: tip.title,
                contentText: tip.description,
                style: ReportButtonStyle.icon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hydration':
        return const Color(0xFF2196F3); // Blue
      case 'nutrition':
      case 'general':
        return const Color(0xFF38e07b); // Green
      case 'portions':
        return const Color(0xFFFF9800); // Orange
      case 'timing':
        return const Color(0xFF9C27B0); // Purple
      case 'protein':
        return const Color(0xFFE91E63); // Pink
      case 'carbs':
      case 'carbohydrates':
        return const Color(0xFFFFEB3B); // Yellow
      case 'vitamins':
        return const Color(0xFF4CAF50); // Light Green
      case 'minerals':
        return const Color(0xFF795548); // Brown
      case 'fiber':
        return const Color(0xFF8BC34A); // Lime
      case 'healthy fats':
      case 'fats':
        return const Color(0xFFFF5722); // Deep Orange
      default:
        return const Color(0xFF38e07b); // Default green
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hydration':
        return Icons.water_drop;
      case 'nutrition':
      case 'general':
        return Icons.restaurant;
      case 'portions':
        return Icons.scale;
      case 'timing':
        return Icons.schedule;
      case 'protein':
        return Icons.fitness_center;
      case 'carbs':
      case 'carbohydrates':
        return Icons.grain;
      case 'vitamins':
        return Icons.local_pharmacy;
      case 'minerals':
        return Icons.diamond;
      case 'fiber':
        return Icons.grass;
      case 'healthy fats':
      case 'fats':
        return Icons.opacity;
      default:
        return Icons.lightbulb;
    }
  }
}
