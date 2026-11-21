import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_models.dart';
import 'nutrition_tips_service.dart';

class StorageService {
  static const String _historyKey = 'food_history';
  static const String _tipsKey = 'nutrition_tips_v3_final_no_images'; // Final version without any images
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _profileSetupKey = 'has_completed_profile_setup';
  static const String _clerkUserIdKey = 'clerk_user_id';
  static const String _clerkAuthSessionKey = 'clerk_is_authenticated';
  static const String _rememberMeKey = 'auth_remember_me';
  static const String _rememberedEmailKey = 'auth_remembered_email';

  // History management
  Future<List<LoggedFoodEntry>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null) return [];
      
      final List<dynamic> historyList = json.decode(historyJson);
      return historyList
          .map((item) => LoggedFoodEntry.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveToHistory(LoggedFoodEntry entry) async {
    try {
      final history = await getHistory();
      history.insert(0, entry);
      
      // Keep only last 100 entries
      if (history.length > 100) {
        history.removeRange(100, history.length);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(history.map((e) => e.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      throw Exception('Failed to save to history: $e');
    }
  }

  /// Efficiently batch-saves entire meal history list in a single disk write
  Future<void> saveAllHistory(List<LoggedFoodEntry> entries) async {
    try {
      final trimmed = entries.take(100).toList();
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(trimmed.map((e) => e.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      throw Exception('Failed to save history list: $e');
    }
  }

  Future<void> removeFromHistory(String id) async {
    try {
      final history = await getHistory();
      history.removeWhere((entry) => entry.id == id);
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(history.map((e) => e.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      throw Exception('Failed to remove from history: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      throw Exception('Failed to clear history: $e');
    }
  }

  // Complete reset of all nutrition tips data - NUCLEAR OPTION
  Future<void> forceResetNutritionTips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get ALL keys and remove any that might contain nutrition data
      final Set<String> allKeys = prefs.getKeys();
      final List<String> keysToRemove = [];
      
      for (final key in allKeys) {
        final keyLower = key.toLowerCase();
        if (keyLower.contains('tips') || keyLower.contains('nutrition_tip')) {
          keysToRemove.add(key);
        }
      }
      
      // Remove all identified keys
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      
      debugPrint('🧹 FORCE RESET: Removed ${keysToRemove.length} cache entries');
      debugPrint('🗑️ Cleared keys: ${keysToRemove.join(', ')}');
      
    } catch (e) {
      debugPrint('⚠️ Failed to force reset: $e');
    }
  }

  // Nutrition tips management - uses fast local cache first to prevent UI freezing
  Future<List<NutritionTip>> getNutritionTips({bool forceRefresh = false}) async {
    try {
      // Return cached tips immediately if available and no force refresh requested
      if (!forceRefresh) {
        final prefs = await SharedPreferences.getInstance();
        final tipsJson = prefs.getString(_tipsKey);
        if (tipsJson != null && tipsJson.isNotEmpty) {
          try {
            final List<dynamic> tipsList = json.decode(tipsJson);
            if (tipsList.isNotEmpty) {
              return tipsList.map((item) => NutritionTip.fromJson(item)).toList();
            }
          } catch (_) {}
        }
      } else {
        await forceResetNutritionTips();
      }
      
      // Try to get fresh tips from Gemini AI or use open-source fallback
      final freshTips = await NutritionTipsService.fetchNutritionTips(count: 6);
      
      // Cache the tips locally
      final prefs = await SharedPreferences.getInstance();
      final tipsJson = json.encode(freshTips.map((t) => t.toJson()).toList());
      await prefs.setString(_tipsKey, tipsJson);
      
      return freshTips;
    } catch (e) {
      debugPrint('⚠️ Failed to fetch fresh tips, using cached tips: $e');
      
      // Fallback to cached tips
      try {
        final prefs = await SharedPreferences.getInstance();
        final tipsJson = prefs.getString(_tipsKey);
        
        if (tipsJson != null) {
          final List<dynamic> tipsList = json.decode(tipsJson);
          return tipsList.map((item) => NutritionTip.fromJson(item)).toList();
        }
      } catch (cacheError) {
        debugPrint('⚠️ Failed to load cached tips: $cacheError');
      }
      
      // Final fallback to default tips
      return _getDefaultTips();
    }
  }

  // Get personalized tips based on user's scan history
  Future<List<NutritionTip>> getPersonalizedTips({int count = 3}) async {
    try {
      final history = await getHistory();
      final recentScans = history.take(10).map((entry) => entry.scanData).toList();
      
      return await NutritionTipsService.generatePersonalizedTips(
        recentScans,
        count: count,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to get personalized tips: $e');
      return await getNutritionTips();
    }
  }

  // Get tips for a specific category
  Future<List<NutritionTip>> getCategoryTips(String category, {int count = 3}) async {
    try {
      return await NutritionTipsService.fetchCategoryTips(category, count: count);
    } catch (e) {
      debugPrint('⚠️ Failed to get category tips: $e');
      // Fallback to all tips filtered by category
      final allTips = await getNutritionTips();
      return allTips
          .where((tip) => tip.category.toLowerCase() == category.toLowerCase())
          .take(count)
          .toList();
    }
  }

  Future<void> saveNutritionTip(NutritionTip tip) async {
    try {
      final tips = await getNutritionTips();
      tips.add(tip);
      
      final prefs = await SharedPreferences.getInstance();
      final tipsJson = json.encode(tips.map((t) => t.toJson()).toList());
      await prefs.setString(_tipsKey, tipsJson);
    } catch (e) {
      throw Exception('Failed to save nutrition tip: $e');
    }
  }

  // Onboarding
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  // Profile Setup Completion
  Future<bool> hasCompletedProfileSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profileSetupKey) ?? false;
  }

  Future<void> setProfileSetupComplete([bool complete = true]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileSetupKey, complete);
  }

  // Clerk User ID & Auth Session
  Future<String?> getClerkUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_clerkUserIdKey);
  }

  Future<void> setClerkUserId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_clerkUserIdKey, id);
    } else {
      await prefs.remove(_clerkUserIdKey);
    }
  }

  Future<bool> isClerkAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_clerkAuthSessionKey) ?? false;
  }

  Future<void> setClerkAuthenticated(bool auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clerkAuthSessionKey, auth);
  }

  // Clear Clerk Session on Logout (preserves user profile, targets, and meal history)
  Future<void> clearAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clerkAuthSessionKey);
    await prefs.remove(_clerkUserIdKey);
  }

  // Remember Me & Saved Email
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? true;
  }

  Future<void> setRememberMe(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, remember);
  }

  Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberedEmailKey);
  }

  Future<void> setRememberedEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email != null && email.isNotEmpty) {
      await prefs.setString(_rememberedEmailKey, email);
    } else {
      await prefs.remove(_rememberedEmailKey);
    }
  }

  List<NutritionTip> _getDefaultTips() {
    return [
      NutritionTip(
        id: '1',
        title: 'Stay Hydrated',
        description: 'Drink at least 8 glasses of water per day to maintain proper hydration and support your metabolism.',
        category: 'Hydration',
        imageUrl: '', // No images - using gradients and icons instead
      ),
      NutritionTip(
        id: '2',
        title: 'Eat the Rainbow',
        description: 'Include a variety of colorful fruits and vegetables in your diet to ensure you get diverse nutrients.',
        category: 'Nutrition',
        imageUrl: '', // No images - using gradients and icons instead
      ),
      NutritionTip(
        id: '3',
        title: 'Portion Control',
        description: 'Use smaller plates and listen to your hunger cues to avoid overeating.',
        category: 'Portions',
        imageUrl: '', // No images - using gradients and icons instead
      ),
      NutritionTip(
        id: '4',
        title: 'Regular Meals',
        description: 'Eat regular meals throughout the day to maintain stable blood sugar levels.',
        category: 'Timing',
        imageUrl: '', // No images - using gradients and icons instead
      ),
      NutritionTip(
        id: '5',
        title: 'Healthy Proteins',
        description: 'Include lean proteins like fish, chicken, beans, and nuts to support muscle health and recovery.',
        category: 'Protein',
        imageUrl: '', // No images - using gradients and icons instead
      ),
      NutritionTip(
        id: '6',
        title: 'Whole Grains',
        description: 'Choose whole grains over refined grains for better fiber intake and sustained energy.',
        category: 'Carbs',
        imageUrl: '', // No images - using gradients and icons instead
      ),
    ];
  }
}
