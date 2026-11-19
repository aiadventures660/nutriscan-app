import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/food_models.dart';
import '../config/api_config.dart';

class MealPlannerService {
  /// Generates a personalized 7-day or 3-day meal plan based on targets and diet style
  static Future<List<MealPlanItem>> generateMealPlan({
    required double targetCalories,
    required double targetProtein,
    String dietaryStyle = 'Balanced High-Protein',
  }) async {
    final prompt = '''
You are an elite sports nutritionist and meal planner.
Generate a structured, healthy 3-day meal prep plan for a user aiming for:
- Calories: ${targetCalories.round()} kcal/day
- Protein: ${targetProtein.round()}g/day
- Dietary Style: $dietaryStyle

Include Breakfast, Lunch, and Dinner for Monday, Tuesday, and Wednesday (9 meals total).
Respond ONLY with a valid JSON array of meal objects:
[
  {
    "day": "Monday",
    "mealType": "Breakfast",
    "title": "Greek Yogurt Berry Crunch Bowl",
    "description": "Thick Greek yogurt topped with fresh blueberries, chia seeds, and chopped walnuts.",
    "calories": 420,
    "protein": 32,
    "carbs": 38,
    "fat": 14,
    "ingredients": ["Greek yogurt", "Blueberries", "Chia seeds", "Walnuts"]
  }
]
''';

    try {
      final text = await _generateWithFallback(prompt);
      final clean = _cleanJson(text);
      final list = json.decode(clean) as List<dynamic>;
      return list.map((item) => MealPlanItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Meal plan generation error: $e, using default curated plan');
      return _getDefaultMealPlan();
    }
  }

  /// Categorizes ingredients into supermarket aisles
  static List<GroceryItem> generateGroceryList(List<MealPlanItem> mealPlan) {
    final Map<String, Set<String>> aisleMap = {
      'Fresh Produce': {'Blueberries', 'Bananas', 'Avocado', 'Spinach', 'Broccoli', 'Garlic', 'Lemon', 'Bell Peppers', 'Sweet Potatoes', 'Apples'},
      'Dairy & Eggs': {'Greek yogurt', 'Eggs', 'Feta cheese', 'Almond milk', 'Cottage cheese', 'Parmesan'},
      'Lean Protein': {'Salmon fillet', 'Chicken breast', 'Tuna steak', 'Tofu', 'Grass-fed beef', 'Whey protein'},
      'Pantry & Grains': {'Quinoa', 'Rolled oats', 'Chia seeds', 'Walnuts', 'Brown rice', 'Black beans', 'Lentils', 'Olive oil'},
    };

    final List<GroceryItem> items = [];
    final Set<String> seen = {};

    for (final meal in mealPlan) {
      for (final ingredient in meal.ingredients) {
        if (!seen.add(ingredient.toLowerCase())) continue;

        String category = 'Pantry & Grains';
        for (final entry in aisleMap.entries) {
          if (entry.value.any((item) => ingredient.toLowerCase().contains(item.toLowerCase()))) {
            category = entry.key;
            break;
          }
        }

        items.add(GroceryItem(
          id: 'grocery_${ingredient.hashCode}',
          name: ingredient,
          category: category,
          quantity: '1 pack',
          isChecked: false,
        ));
      }
    }

    if (items.isEmpty) {
      return _getDefaultGroceryList();
    }
    return items;
  }

  static Future<String> _generateWithFallback(String prompt) async {
    dynamic lastError;
    for (final modelName in ApiConfig.fallbackModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: ApiConfig.googleAiApiKey,
          generationConfig: GenerationConfig(
            temperature: 0.4,
            topK: 32,
            topP: 0.9,
            maxOutputTokens: 2048,
          ),
        );
        final res = await model.generateContent([Content.text(prompt)])
            .timeout(ApiConfig.requestTimeout);
        final txt = res.text?.trim() ?? '';
        if (txt.isNotEmpty) return txt;
      } catch (err) {
        lastError = err;
      }
    }
    throw Exception('Failed to generate meal plan: $lastError');
  }

  static String _cleanJson(String raw) {
    String clean = raw.trim();
    if (clean.startsWith('```json')) clean = clean.substring(7);
    if (clean.startsWith('```')) clean = clean.substring(3);
    if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
    final s = clean.indexOf('[');
    final e = clean.lastIndexOf(']') + 1;
    if (s != -1 && e > s) return clean.substring(s, e).trim();
    return clean.trim();
  }

  static List<MealPlanItem> getDefaultMealPlan() {
    return _getDefaultMealPlan();
  }

  static List<GroceryItem> getDefaultGroceryList() {
    return _getDefaultGroceryList();
  }

  static List<MealPlanItem> _getDefaultMealPlan() {
    return [
      MealPlanItem(
        day: 'Monday',
        mealType: 'Breakfast',
        title: 'Avocado & Poached Egg Sourdough',
        description: 'Two poached eggs over mashed avocado on artisan sourdough with microgreens.',
        calories: 450,
        protein: 24,
        carbs: 38,
        fat: 22,
        ingredients: ['Eggs', 'Avocado', 'Sourdough bread', 'Microgreens'],
      ),
      MealPlanItem(
        day: 'Monday',
        mealType: 'Lunch',
        title: 'Grilled Salmon Quinoa Bowl',
        description: 'Herb-crusted salmon with seasoned quinoa, steamed broccoli, and lemon drizzle.',
        calories: 580,
        protein: 42,
        carbs: 48,
        fat: 18,
        ingredients: ['Salmon fillet', 'Quinoa', 'Broccoli', 'Lemon', 'Olive oil'],
      ),
      MealPlanItem(
        day: 'Monday',
        mealType: 'Dinner',
        title: 'Lemon Herb Chicken Breast & Sweet Potato',
        description: 'Tender grilled chicken breast served with roasted sweet potato cubes and asparagus.',
        calories: 520,
        protein: 46,
        carbs: 44,
        fat: 12,
        ingredients: ['Chicken breast', 'Sweet Potatoes', 'Asparagus', 'Garlic'],
      ),
      MealPlanItem(
        day: 'Tuesday',
        mealType: 'Breakfast',
        title: 'Overnight Rolled Oats with Chia & Berries',
        description: 'Slow-digesting oats soaked in almond milk with chia seeds, blueberries, and honey.',
        calories: 390,
        protein: 18,
        carbs: 58,
        fat: 10,
        ingredients: ['Rolled oats', 'Almond milk', 'Chia seeds', 'Blueberries'],
      ),
      MealPlanItem(
        day: 'Tuesday',
        mealType: 'Lunch',
        title: 'Mediterranean Tuna & Chickpea Salad',
        description: 'Flaked albacore tuna tossed with crisp cucumbers, cherry tomatoes, and chickpeas.',
        calories: 490,
        protein: 38,
        carbs: 42,
        fat: 14,
        ingredients: ['Tuna steak', 'Cucumbers', 'Cherry tomatoes', 'Chickpeas'],
      ),
      MealPlanItem(
        day: 'Tuesday',
        mealType: 'Dinner',
        title: 'Tofu & Vegetable Stir-Fry over Brown Rice',
        description: 'Crispy sesame-ginger tofu with bell peppers, snap peas, and steamed brown rice.',
        calories: 460,
        protein: 26,
        carbs: 54,
        fat: 14,
        ingredients: ['Tofu', 'Bell Peppers', 'Brown rice', 'Soy sauce'],
      ),
    ];
  }

  static List<GroceryItem> _getDefaultGroceryList() {
    return [
      GroceryItem(id: 'g1', name: 'Avocados (Bag of 4)', category: 'Fresh Produce', quantity: '1 bag'),
      GroceryItem(id: 'g2', name: 'Organic Blueberries', category: 'Fresh Produce', quantity: '250g'),
      GroceryItem(id: 'g3', name: 'Broccoli Crowns', category: 'Fresh Produce', quantity: '2 heads'),
      GroceryItem(id: 'g4', name: 'Pasture-Raised Eggs', category: 'Dairy & Eggs', quantity: '1 dozen'),
      GroceryItem(id: 'g5', name: 'Greek Yogurt 0% Fat', category: 'Dairy & Eggs', quantity: '500g'),
      GroceryItem(id: 'g6', name: 'Fresh Atlantic Salmon', category: 'Lean Protein', quantity: '400g'),
      GroceryItem(id: 'g7', name: 'Free-Range Chicken Breast', category: 'Lean Protein', quantity: '600g'),
      GroceryItem(id: 'g8', name: 'Organic Quinoa', category: 'Pantry & Grains', quantity: '500g'),
      GroceryItem(id: 'g9', name: 'Rolled Oats', category: 'Pantry & Grains', quantity: '1 kg'),
      GroceryItem(id: 'g10', name: 'Cold-Pressed Olive Oil', category: 'Pantry & Grains', quantity: '500ml'),
    ];
  }
}
