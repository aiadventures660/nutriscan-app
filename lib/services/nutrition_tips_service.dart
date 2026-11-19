import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/food_models.dart';
import '../config/api_config.dart';

class NutritionTipsService {
  static void _log(String message) {
    if (kDebugMode) {
      debugPrint(ApiConfig.sanitizeLog(message));
    }
  }
  static const List<String> _tipCategories = [
    'Hydration',
    'Nutrition',
    'Portions',
    'Timing',
    'Protein',
    'Carbs',
    'Vitamins',
    'Minerals',
    'Fiber',
    'Healthy Fats'
  ];

  /// Helper to clean JSON string from markdown wrappers
  static String _cleanJsonMarkdown(String raw) {
    String clean = raw.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}') + 1;
    if (start != -1 && end > start) {
      return clean.substring(start, end).trim();
    }
    return clean.trim();
  }

  /// Safely generates text using Gemini with multi-model fallback resilience
  static Future<String> _generateWithFallback(String prompt) async {
    if (!ApiConfig.isApiKeyConfigured) {
      throw Exception('Gemini API key not configured');
    }

    dynamic lastError;
    for (final modelName in ApiConfig.fallbackModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: ApiConfig.googleAiApiKey,
        );
        final response = await model.generateContent([Content.text(prompt)])
            .timeout(ApiConfig.requestTimeout);
        final responseText = response.text?.trim() ?? '';
        if (responseText.isNotEmpty) {
          return responseText;
        }
      } catch (e) {
        lastError = e;
        _log('⚠️ Gemini model $modelName tips error: $e, trying next fallback...');
      }
    }
    throw Exception(ApiConfig.sanitizeLog('All Gemini models failed: $lastError'));
  }

  /// Fetches nutrition tips using Gemini AI or fallback to open-source tips
  /// Ensures unique tips by adding timestamp to IDs
  static Future<List<NutritionTip>> fetchNutritionTips({int count = 6}) async {
    try {
      // Try Gemini AI first
      final geminiTips = await _fetchGeminiTips(count);
      if (geminiTips.isNotEmpty) {
        _log('✅ Successfully fetched ${geminiTips.length} unique tips from Gemini AI');
        return geminiTips;
      }
    } catch (e) {
      _log('⚠️ Gemini AI failed: $e');
    }

    // Fallback to open-source tips with unique IDs
    _log('📚 Using open-source nutrition tips fallback with unique timestamps');
    final tips = _getOpenSourceTips(count);
    
    // Add timestamp to make tips unique each time
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return tips.map((tip) => NutritionTip(
      id: '${tip.id}_$timestamp',
      title: tip.title,
      description: tip.description,
      category: tip.category,
      imageUrl: '', // No images - using gradients and icons instead
    )).toList();
  }

  /// Fetches tips from Gemini AI
  static Future<List<NutritionTip>> _fetchGeminiTips(int count) async {
    final prompt = '''
Generate $count completely unique, practical nutrition tips in JSON format. Focus on food-specific advice, cooking tips, and meal planning strategies.

Required JSON structure:
{
  "tips": [
    {
      "id": "unique_id_${DateTime.now().millisecondsSinceEpoch}",
      "title": "Food-specific, actionable title (max 50 chars)",
      "description": "Detailed, practical food advice with specific examples (150-250 chars)",
      "category": "One of: Hydration, Nutrition, Portions, Timing, Protein, Carbs, Vitamins, Minerals, Fiber, Healthy Fats"
    }
  ]
}

Guidelines:
- Focus on specific foods, cooking methods, or meal combinations
- Include real food examples (e.g., "Add spinach to your morning eggs")
- Provide practical kitchen tips and food preparation advice
- Mention specific nutrients found in foods
- Include timing advice for meals and snacks
- Vary categories to cover different nutrition aspects
- Make each tip immediately actionable with clear food choices
- Avoid generic advice - be specific about foods and portions

Examples of good tips:
- "Pair iron-rich spinach with vitamin C foods like bell peppers to boost absorption"
- "Eat protein within 30 minutes after workout - try Greek yogurt with berries"
- "Add turmeric to your rice for anti-inflammatory benefits and golden color"

Generate $count unique tips that someone can implement today with specific foods.
Return only valid JSON without any markdown formatting.
''';

    try {
      final responseText = await _generateWithFallback(prompt);
      final cleanJson = _cleanJsonMarkdown(responseText);

      final jsonData = json.decode(cleanJson);
      final tipsData = jsonData['tips'] as List;

      return tipsData.asMap().entries.map((entry) {
        final index = entry.key;
        final tip = entry.value;
        return NutritionTip(
          id: tip['id'] ?? 'gemini_${DateTime.now().millisecondsSinceEpoch}_$index',
          title: tip['title'] ?? 'Nutrition Tip',
          description: tip['description'] ?? 'Stay healthy with good nutrition habits.',
          category: tip['category'] ?? _tipCategories[index % _tipCategories.length],
          imageUrl: '', // No images - using gradients and icons instead
        );
      }).toList();
    } catch (e) {
      _log('❌ Error processing Gemini response: $e');
      throw Exception(ApiConfig.sanitizeLog('Failed to process Gemini AI response: $e'));
    }
  }

  /// Open-source fallback nutrition tips with specific food advice
  static List<NutritionTip> _getOpenSourceTips(int count) {
    final openSourceTips = [
      NutritionTip(
        id: 'food_tip_1',
        title: 'Start Your Day with Protein',
        description: 'Add 2 eggs or Greek yogurt to breakfast for sustained energy. Protein helps stabilize blood sugar and keeps you full longer.',
        category: 'Protein',
        imageUrl: '', // No images - using gradients and icons instead
      ),
      NutritionTip(
        id: 'food_tip_2',
        title: 'Colorful Vegetable Portions',
        description: 'Fill half your plate with colorful vegetables like bell peppers, broccoli, and carrots for maximum nutrient variety.',
        category: 'Nutrition',
        imageUrl: '', // No images - using gradients and icons instead
      ),
      NutritionTip(
        id: 'food_tip_3',
        title: 'Smart Hydration Habit',
        description: 'Drink a glass of water before each meal. Staying hydrated aids digestion and prevents overeating by distinguishing thirst from hunger.',
        category: 'Hydration',
        imageUrl: '', // No images - using gradients and icons instead
      ),
      NutritionTip(
        id: 'food_tip_4',
        title: 'Healthy Snack Planning',
        description: 'Keep almonds, walnuts, or apple slices handy for mid-afternoon cravings. Healthy fats and fiber keep energy levels steady.',
        category: 'Portions',
        imageUrl: '', // No images - using gradients and icons instead
      ),
      NutritionTip(
        id: 'food_tip_5',
        title: 'Eat Within Your Window',
        description: 'Try eating dinner 2-3 hours before bedtime to improve digestion and sleep quality while supporting overnight metabolic health.',
        category: 'Timing',
        imageUrl: '', // No images - using gradients and icons instead
      ),
      NutritionTip(
        id: 'food_tip_6',
        title: 'Fiber-Rich Grains',
        description: 'Swap white rice with quinoa, brown rice, or oats to increase soluble fiber and support cardiovascular health.',
        category: 'Fiber',
        imageUrl: '', // No images - using gradients and icons instead
      ),
    ];

    // Shuffle and return requested count
    final random = Random();
    final shuffled = List<NutritionTip>.from(openSourceTips)..shuffle(random);
    return shuffled.take(count).toList();
  }

  /// Get tips for a specific category using Gemini AI
  static Future<List<NutritionTip>> fetchCategoryTips(String category, {int count = 3}) async {
    try {
      final prompt = '''
Generate $count specific nutrition tips about "$category" in JSON format.

Required JSON structure:
{
  "tips": [
    {
      "id": "unique_id",
      "title": "Short, catchy title (max 50 chars)",
      "description": "Detailed, practical description (100-200 chars)",
      "category": "$category"
    }
  ]
}

Focus specifically on $category-related advice. Make tips actionable and evidence-based.
Return only valid JSON without any markdown formatting.
''';

      final responseText = await _generateWithFallback(prompt);
      final cleanJson = _cleanJsonMarkdown(responseText);

      final jsonData = json.decode(cleanJson);
      final tipsData = jsonData['tips'] as List;

      return tipsData.asMap().entries.map((entry) {
        final index = entry.key;
        final tip = entry.value;
        return NutritionTip(
          id: tip['id'] ?? 'gemini_${category.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}_$index',
          title: tip['title'] ?? '$category Tip',
          description: tip['description'] ?? 'Important advice about $category.',
          category: category,
          imageUrl: '', // No images - using gradients and icons instead
        );
      }).toList();
    } catch (e) {
      _log('⚠️ Failed to fetch $category tips from Gemini: $e');
      // Fallback to open-source category tips
      return _getOpenSourceTips(12)
          .where((tip) => tip.category.toLowerCase() == category.toLowerCase())
          .take(count)
          .toList();
    }
  }

  /// Generate personalized tips based on user's recent scans
  static Future<List<NutritionTip>> generatePersonalizedTips(
    List<ScanData> recentScans, {
    int count = 3
  }) async {
    if (recentScans.isEmpty) {
      return fetchNutritionTips(count: count);
    }

    try {
      // Analyze recent scan patterns
      final foodNames = recentScans.map((scan) => scan.foodName).take(5).toList();
      final healthScores = recentScans.map((scan) => scan.healthScore).take(5).toList();

      final prompt = '''
Based on the user's recent food scans, generate $count personalized nutrition tips in JSON format.

Recent foods scanned: ${foodNames.join(', ')}
Health scores: ${healthScores.join(', ')}

Required JSON structure:
{
  "tips": [
    {
      "id": "unique_id",
      "title": "Short, catchy title (max 50 chars)",
      "description": "Detailed, practical description (100-200 chars)",
      "category": "One of: Hydration, Nutrition, Portions, Timing, Protein, Carbs, Vitamins, Minerals, Fiber, Healthy Fats"
    }
  ]
}

Analyze their eating patterns and provide relevant, personalized advice to help them improve their nutrition.
Return only valid JSON without any markdown formatting.
''';

      final responseText = await _generateWithFallback(prompt);
      final cleanJson = _cleanJsonMarkdown(responseText);

      final jsonData = json.decode(cleanJson);
      final tipsData = jsonData['tips'] as List;

      return tipsData.asMap().entries.map((entry) {
        final index = entry.key;
        final tip = entry.value;
        return NutritionTip(
          id: tip['id'] ?? 'personalized_${DateTime.now().millisecondsSinceEpoch}_$index',
          title: tip['title'] ?? 'Personalized Tip',
          description: tip['description'] ?? 'Personalized nutrition advice based on your scans.',
          category: tip['category'] ?? 'Nutrition',
          imageUrl: '', // No images - using gradients and icons instead
        );
      }).toList();
    } catch (e) {
      _log('⚠️ Failed to generate personalized tips: $e');
      // Fallback to regular tips
      return fetchNutritionTips(count: count);
    }
  }
}
