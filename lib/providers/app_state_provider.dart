import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../models/food_models.dart';
import '../services/storage_service.dart';
import '../services/meal_planner_service.dart';
import '../services/health_sync_service.dart';
import '../services/ai_service.dart';
import '../services/api_client.dart';

class AppStateProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<LoggedFoodEntry> _history = [];
  List<NutritionTip> _nutritionTips = [];
  ScanData? _currentScanData;
  bool _isLoading = false;
  String _currentView = 'home';
  String _userProfileName = 'Nutrition User';
  String _userProfileEmail = '';
  String? _userPhotoPath;
  String? _clerkUserId;
  bool _isClerkLoggedIn = false;

  String? get clerkUserId => _clerkUserId;
  bool get isClerkLoggedIn => _isClerkLoggedIn;

  // Google AI Free-Tier Model & Custom API Key
  String _selectedAiModel = 'gemini-flash-lite-latest';
  String _customApiKey = '';

  String get selectedAiModel => _selectedAiModel;
  GeminiModelInfo get activeModelInfo =>
      ApiConfig.getModelInfo(_selectedAiModel);
  String get customApiKey => _customApiKey;
  bool get hasCustomApiKey => _customApiKey.trim().isNotEmpty;
  String get effectiveApiKey => ApiConfig.effectiveApiKey;

  Future<void> setSelectedAiModel(String modelId) async {
    _selectedAiModel = modelId;
    ApiConfig.activeModel = modelId;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_ai_model', modelId);
    } catch (_) {}
  }

  Future<void> setCustomApiKey(String key) async {
    _customApiKey = key.trim();
    ApiConfig.customApiKey = _customApiKey.isNotEmpty ? _customApiKey : null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customApiKey.isEmpty) {
        await prefs.remove('custom_google_ai_key');
      } else {
        await prefs.setString(
            'custom_google_ai_key', ApiConfig.encodeKey(_customApiKey));
      }
    } catch (_) {}
  }

  Future<void> resetToDefaultApiKey() async {
    await setCustomApiKey('');
  }

  /// Test connectivity for a specific model using either custom or default API key
  Future<Map<String, dynamic>> testAiModelConnection(
      {String? modelId, String? apiKey}) async {
    final targetModel = modelId ?? _selectedAiModel;
    final targetKey = (apiKey != null && apiKey.trim().isNotEmpty)
        ? apiKey.trim()
        : ApiConfig.effectiveApiKey;
    return await AIService.testModelConnection(
      modelId: targetModel,
      apiKey: targetKey,
    );
  }

  // Theme Management
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    AppTheme.setDarkMode(mode == ThemeMode.dark);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme_mode', mode.name);
      if (_clerkUserId != null && _clerkUserId!.isNotEmpty) {
        ApiClient().updatePreferences({'theme': mode.name}).catchError((_) => null);
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final nextMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  Future<void> setBackendUrl(String url) async {
    ApiConfig.setBackendUrl(url);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_backend_url', url.trim());
    } catch (_) {}
  }

  // User Profile & Metabolic Metrics
  int _userAge = 26;
  String _userGender = 'Female';
  double _userHeightCm = 170.0;
  double _userWeightKg = 65.0;
  String _userActivityLevel = 'Moderately Active';
  String _userGoal = 'Healthy Lifestyle';

  int get userAge => _userAge;
  String get userGender => _userGender;
  double get userHeightCm => _userHeightCm;
  double get userWeightKg => _userWeightKg;
  String get userActivityLevel => _userActivityLevel;
  String get userGoal => _userGoal;

  // Macro & Calorie Targets
  double _calorieTarget = 2100;
  double _proteinTarget = 140; // grams
  double _carbsTarget = 220; // grams
  double _fatTarget = 65; // grams

  // Hydration Tracker
  int _waterIntakeMl = 1250;
  final int _waterTargetMl = 2500;

  // 1. Favorites System
  List<FavoriteMeal> _favorites = [];

  // 2. Multi-Item Meal Basket
  final List<ScanData> _mealBasket = [];

  // 3. AI Meal Plan & Smart Grocery List
  List<MealPlanItem> _mealPlan = [];
  List<GroceryItem> _groceryList = [];

  // 4. Health Connect / Apple Health Integration
  bool _isHealthSyncEnabled = true;

  // Getters
  List<LoggedFoodEntry> get history => _history;
  List<NutritionTip> get nutritionTips => _nutritionTips;
  ScanData? get currentScanData => _currentScanData;
  bool get isLoading => _isLoading;
  String get currentView => _currentView;

  double get calorieTarget => _calorieTarget;
  double get proteinTarget => _proteinTarget;
  double get carbsTarget => _carbsTarget;
  double get fatTarget => _fatTarget;

  int get waterIntakeMl => _waterIntakeMl;
  int get waterTargetMl => _waterTargetMl;
  double get waterProgress => (_waterIntakeMl / _waterTargetMl).clamp(0.0, 1.0);

  List<FavoriteMeal> get favorites => _favorites;
  List<ScanData> get mealBasket => _mealBasket;
  List<MealPlanItem> get mealPlan => _mealPlan;
  List<MealPlanItem> get currentMealPlan => _mealPlan;
  bool get isGeneratingMealPlan => _isLoading;
  List<GroceryItem> get groceryList => _groceryList;
  bool get isHealthSyncEnabled => _isHealthSyncEnabled;
  bool get isHealthConnectSynced => _isHealthSyncEnabled;

  HealthSyncData get healthSyncData =>
      HealthSyncService.getHealthSyncData(isEnabled: _isHealthSyncEnabled);

  String get userProfileName => _userProfileName;
  String get userProfileEmail => _userProfileEmail;
  String? get userPhotoPath => _userPhotoPath;

  Future<void> setUserProfile(String name, String email) async {
    _userProfileName = name;
    _userProfileEmail = email;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
    } catch (_) {}
  }

  Future<void> setUserPhoto(String? photoPath) async {
    _userPhotoPath = photoPath;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (photoPath == null || photoPath.isEmpty) {
        await prefs.remove('user_photo_path');
      } else {
        await prefs.setString('user_photo_path', photoPath);
      }
    } catch (_) {}
  }

  static String _formatEnumString(String val) {
    if (val.isEmpty) return val;
    return val
        .split('_')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  /// Automatically fetch and restore authenticated user data from Supabase via backend API:
  /// - User Profile & Onboarding Data
  /// - Meal History & Food Scans
  /// - Dashboard Nutrition Data & Hydration
  /// - User Preferences
  Future<void> restoreUserDataFromBackend({
    required String clerkId,
    String? fallbackEmail,
    String? fallbackName,
    String? photoUrl,
  }) async {
    _clerkUserId = clerkId;
    _isClerkLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clerk_user_id', clerkId);
    await prefs.setBool('clerk_is_authenticated', true);

    // 1. Fetch user profile from Supabase
    try {
      final res = await ApiClient().getProfile();
      if (res != null && res['data'] != null) {
        final profile = res['data'] as Map<String, dynamic>;
        final pName = profile['name'] as String?;
        if (pName != null && pName.trim().isNotEmpty) {
          _userProfileName = pName.trim();
        } else if (fallbackName != null && fallbackName.trim().isNotEmpty) {
          _userProfileName = fallbackName.trim();
        }

        final pEmail = profile['email'] as String?;
        if (pEmail != null && pEmail.trim().isNotEmpty) {
          _userProfileEmail = pEmail.trim();
        } else if (fallbackEmail != null && fallbackEmail.trim().isNotEmpty) {
          _userProfileEmail = fallbackEmail.trim();
        }

        final pPhoto = (profile['profileImageUrl'] ?? profile['avatarUrl']) as String?;
        if (pPhoto != null && pPhoto.trim().isNotEmpty) {
          _userPhotoPath = pPhoto.trim();
        } else if (photoUrl != null && photoUrl.trim().isNotEmpty) {
          _userPhotoPath = photoUrl.trim();
        }

        if (profile['age'] != null) {
          _userAge = (profile['age'] as num).toInt();
        }
        if (profile['gender'] != null) {
          _userGender = _formatEnumString(profile['gender'].toString());
        }
        if (profile['heightCm'] != null) {
          _userHeightCm = (profile['heightCm'] as num).toDouble();
        }
        if (profile['weightKg'] != null) {
          _userWeightKg = (profile['weightKg'] as num).toDouble();
        }
        if (profile['activityLevel'] != null) {
          _userActivityLevel = _formatEnumString(profile['activityLevel'].toString());
        }
        if (profile['goal'] != null) {
          _userGoal = _formatEnumString(profile['goal'].toString());
        }

        if (profile['targetCalories'] != null) {
          _calorieTarget = (profile['targetCalories'] as num).toDouble();
        }
        if (profile['targetProtein'] != null) {
          _proteinTarget = (profile['targetProtein'] as num).toDouble();
        }
        if (profile['targetCarbs'] != null) {
          _carbsTarget = (profile['targetCarbs'] as num).toDouble();
        }
        if (profile['targetFat'] != null) {
          _fatTarget = (profile['targetFat'] as num).toDouble();
        }
        if (profile['targetWaterMl'] != null) {
          // Keep target water synced
        }

        // Persist restored profile and targets to local SharedPreferences
        await prefs.setString('user_name', _userProfileName);
        await prefs.setString('user_email', _userProfileEmail);
        if (_userPhotoPath != null) {
          await prefs.setString('user_photo_path', _userPhotoPath!);
        }
        await prefs.setInt('user_age', _userAge);
        await prefs.setString('user_gender', _userGender);
        await prefs.setDouble('user_height_cm', _userHeightCm);
        await prefs.setDouble('user_weight_kg', _userWeightKg);
        await prefs.setString('user_activity_level', _userActivityLevel);
        await prefs.setString('user_goal', _userGoal);
        await prefs.setDouble('target_calories', _calorieTarget);
        await prefs.setDouble('target_protein', _proteinTarget);
        await prefs.setDouble('target_carbs', _carbsTarget);
        await prefs.setDouble('target_fat', _fatTarget);
      } else {
        // If profile does not exist on backend yet (brand new account), sync initial onboarding data once
        if (fallbackName != null && fallbackName.isNotEmpty) {
          _userProfileName = fallbackName;
        }
        if (fallbackEmail != null && fallbackEmail.isNotEmpty) {
          _userProfileEmail = fallbackEmail;
        }
        if (photoUrl != null && photoUrl.isNotEmpty) {
          _userPhotoPath = photoUrl;
        }

        ApiClient().syncOnboardingProfile({
          'name': _userProfileName,
          'age': _userAge,
          'gender': _userGender,
          'heightCm': _userHeightCm,
          'weightKg': _userWeightKg,
          'goal': _userGoal,
          'activityLevel': _userActivityLevel,
          'targetCalories': _calorieTarget,
          'targetProtein': _proteinTarget,
          'targetCarbs': _carbsTarget,
          'targetFat': _fatTarget,
          'targetWaterMl': _waterTargetMl,
        }).catchError((_) => null);
      }
    } catch (e) {
      debugPrint('restoreUserDataFromBackend (profile) error: $e');
    }

    // 2. Fetch user meals from Supabase
    try {
      final backendMeals = await ApiClient().getMeals(limit: 100);
      if (backendMeals != null) {
        _history.clear();
        await _storageService.clearHistory();

        for (final m in backendMeals) {
          final mealMap = m as Map<String, dynamic>;
          final cal = (mealMap['calories'] as num?)?.toDouble() ?? 0;
          final p = (mealMap['protein'] as num?)?.toDouble() ?? 0;
          final c = (mealMap['carbs'] as num?)?.toDouble() ?? 0;
          final f = (mealMap['fat'] as num?)?.toDouble() ?? 0;
          final foodName = mealMap['name'] as String? ?? 'Meal';
          final mealType = mealMap['mealType'] as String? ?? 'Snack';
          final loggedAt =
              DateTime.tryParse(mealMap['loggedAt'] as String? ?? '') ??
                  DateTime.now();

          final scan = ScanData(
            foodName: foodName,
            nutritionInfo:
                'Calories: ${cal.round()} kcal, Protein: ${p.round()}g, Carbs: ${c.round()}g, Fat: ${f.round()}g',
            healthScore: mealMap['healthScore'] as String? ?? 'Good',
            recommendations: mealMap['recommendations'] as String? ?? '',
            vitaminsAndMinerals: const [],
            imagePath: mealMap['imageUrl'] as String? ?? '',
            timestamp: loggedAt,
            novaGroup: (mealMap['novaGroup'] as num?)?.toInt() ?? 1,
          );

          final entry = LoggedFoodEntry(
            id: mealMap['id'] as String? ??
                loggedAt.millisecondsSinceEpoch.toString(),
            scanData: scan,
            timestamp: loggedAt,
            parsedNutrition: ParsedNutritionValues(
              calories: cal,
              protein: p,
              carbs: c,
              fat: f,
            ),
            mealType: mealType,
          );

          _history.add(entry);
          await _storageService.saveToHistory(entry);
        }
      }
    } catch (e) {
      debugPrint('restoreUserDataFromBackend (meals) error: $e');
    }

    // 3. Fetch daily summary and hydration
    try {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final summaryRes = await ApiClient().getDailySummary(todayStr);
      if (summaryRes != null && summaryRes['data'] != null) {
        final data = summaryRes['data'] as Map<String, dynamic>;
        if (data['totalWaterMl'] != null) {
          _waterIntakeMl = (data['totalWaterMl'] as num).toInt();
          final todayKey = 'water_${now.year}_${now.month}_${now.day}';
          await prefs.setInt(todayKey, _waterIntakeMl);
        }
      }
    } catch (e) {
      debugPrint('restoreUserDataFromBackend (hydration) error: $e');
    }

    // 4. Fetch preferences
    try {
      final prefsRes = await ApiClient().getPreferences();
      if (prefsRes != null && prefsRes['data'] != null) {
        final pData = prefsRes['data'] as Map<String, dynamic>;
        if (pData['theme'] != null) {
          final theme = pData['theme'] as String;
          if (theme == 'dark') {
            _themeMode = ThemeMode.dark;
            AppTheme.setDarkMode(true);
          } else if (theme == 'system') {
            _themeMode = ThemeMode.system;
          } else {
            _themeMode = ThemeMode.light;
            AppTheme.setDarkMode(false);
          }
        }
      }
    } catch (e) {
      debugPrint('restoreUserDataFromBackend (preferences) error: $e');
    }

    notifyListeners();
  }

  Future<void> linkClerkAccount({
    required String? clerkId,
    String? email,
    String? name,
    String? photoUrl,
  }) async {
    if (clerkId == null || clerkId.isEmpty) {
      await onClerkLogout();
      return;
    }

    await restoreUserDataFromBackend(
      clerkId: clerkId,
      fallbackEmail: email,
      fallbackName: name,
      photoUrl: photoUrl,
    );
  }

  /// Synchronize active Clerk user profile across all screens
  Future<void> syncClerkUserData({
    required String clerkId,
    required String? email,
    required String? name,
    String? photoUrl,
  }) async {
    if (_clerkUserId != clerkId || _history.isEmpty) {
      await restoreUserDataFromBackend(
        clerkId: clerkId,
        fallbackEmail: email,
        fallbackName: name,
        photoUrl: photoUrl,
      );
      return;
    }

    bool changed = false;
    if (email != null && email.isNotEmpty && email != _userProfileEmail) {
      _userProfileEmail = email;
      changed = true;
    }
    if (name != null && name.isNotEmpty && name != _userProfileName) {
      _userProfileName = name;
      changed = true;
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (_userPhotoPath == null || _userPhotoPath!.startsWith('http')) {
        if (_userPhotoPath != photoUrl) {
          _userPhotoPath = photoUrl;
          changed = true;
        }
      }
    }

    if (changed) {
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('clerk_user_id', clerkId);
        await prefs.setBool('clerk_is_authenticated', true);
        if (_userProfileEmail.isNotEmpty) {
          await prefs.setString('user_email', _userProfileEmail);
        }
        if (_userProfileName.isNotEmpty) {
          await prefs.setString('user_name', _userProfileName);
        }
        if (_userPhotoPath != null) {
          await prefs.setString('user_photo_path', _userPhotoPath!);
        }
      } catch (_) {}
    }
  }

  Future<void> onClerkLogout() async {
    _clerkUserId = null;
    _isClerkLoggedIn = false;
    _history.clear();
    _mealBasket.clear();
    _currentScanData = null;
    _userProfileName = 'Nutrition User';
    _userProfileEmail = '';
    _userPhotoPath = null;
    _waterIntakeMl = 0;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('clerk_user_id');
      await prefs.setBool('clerk_is_authenticated', false);
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_photo_path');
      await _storageService.clearHistory();
      await _storageService.clearAuthSession();
      ApiClient().setSessionToken(null);
      ApiClient().setTokenProvider(null);
    } catch (_) {}
  }

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Initialize app state: loads all user profile, photo, targets, history, tips & favorites
  // before the first frame of the homepage is rendered.
  Future<void> initialize({bool force = false}) async {
    if (_isInitialized && !force) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. User Profile, Photo & Theme
      _userProfileName = prefs.getString('user_name') ?? 'Nutrition User';
      _userProfileEmail = prefs.getString('user_email') ?? '';
      _userPhotoPath = prefs.getString('user_photo_path');
      _clerkUserId = prefs.getString('clerk_user_id');
      _isClerkLoggedIn = prefs.getBool('clerk_is_authenticated') ?? false;

      // AI Model and Custom Key configuration (with obfuscation decoding & obsolete model safety)
      _selectedAiModel =
          prefs.getString('selected_ai_model') ?? 'gemini-flash-lite-latest';
      if (!ApiConfig.freeTierModels.any((m) =>
          m.id == _selectedAiModel || m.apiModelId == _selectedAiModel)) {
        _selectedAiModel = 'gemini-flash-lite-latest';
      }
      final rawStoredKey = prefs.getString('custom_google_ai_key') ?? '';
      _customApiKey = ApiConfig.decodeKey(rawStoredKey);
      ApiConfig.activeModel = _selectedAiModel;
      ApiConfig.customApiKey = _customApiKey.isNotEmpty ? _customApiKey : null;

      final customBackendUrl = prefs.getString('custom_backend_url');
      if (customBackendUrl != null && customBackendUrl.trim().isNotEmpty) {
        ApiConfig.setBackendUrl(customBackendUrl);
      }

      final themeModeStr = prefs.getString('app_theme_mode') ?? 'light';
      if (themeModeStr == 'dark') {
        _themeMode = ThemeMode.dark;
        AppTheme.setDarkMode(true);
      } else if (themeModeStr == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.light;
        AppTheme.setDarkMode(false);
      }

      // 2. Targets & Metabolic Metrics
      final todayKey =
          'water_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}';
      _waterIntakeMl = prefs.getInt(todayKey) ?? 1250;
      _calorieTarget = prefs.getDouble('target_calories') ?? 2100;
      _proteinTarget = prefs.getDouble('target_protein') ?? 140;
      _carbsTarget = prefs.getDouble('target_carbs') ?? 220;
      _fatTarget = prefs.getDouble('target_fat') ?? 65;

      _userAge = prefs.getInt('user_age') ?? 26;
      _userGender = prefs.getString('user_gender') ?? 'Female';
      _userHeightCm = prefs.getDouble('user_height_cm') ?? 170.0;
      _userWeightKg = prefs.getDouble('user_weight_kg') ?? 65.0;
      _userActivityLevel =
          prefs.getString('user_activity_level') ?? 'Moderately Active';
      _userGoal = prefs.getString('user_goal') ?? 'Healthy Lifestyle';

      // 3. Health Sync Setting
      _isHealthSyncEnabled = prefs.getBool('health_sync_enabled') ?? true;

      // 4. Favorites
      final favsJson = prefs.getStringList('user_favorites_v1');
      if (favsJson != null && favsJson.isNotEmpty) {
        _favorites = favsJson.map((str) {
          final map = json.decode(str) as Map<String, dynamic>;
          return FavoriteMeal.fromSimple(
            foodName: map['name'] ?? '',
            nutritionInfo: map['nutritionInfo'] ?? '',
            healthScore: map['healthScore'] ?? '8/10',
            recommendations: map['recommendations'] ?? '',
            ingredients: (map['ingredients'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            vitaminsAndMinerals: const [],
            defaultMealType: map['mealType'] ?? 'Snacks',
          );
        }).toList();
      } else {
        _favorites = [];
      }

      // 5. Food History & Nutrition Tips in parallel
      await Future.wait([
        _loadHistoryInternal(),
        _loadNutritionTipsInternal(),
      ]);

      // 6. Meal Plan & Grocery
      _loadInitialMealPlanAndGrocery();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during comprehensive initialize(): $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadHistoryInternal() async {
    try {
      _history = await _storageService.getHistory();
      _history.removeWhere((entry) =>
          entry.id.startsWith('sample_') ||
          entry.scanData.id.startsWith('scan_sample_'));

      // If user has no local history, fetch their real saved meals from backend
      if (_history.isEmpty) {
        final backendMeals = await ApiClient().getMeals(limit: 50);
        if (backendMeals != null && backendMeals.isNotEmpty) {
          for (final m in backendMeals) {
            final mealMap = m as Map<String, dynamic>;
            final cal = (mealMap['calories'] as num?)?.toDouble() ?? 0;
            final p = (mealMap['protein'] as num?)?.toDouble() ?? 0;
            final c = (mealMap['carbs'] as num?)?.toDouble() ?? 0;
            final f = (mealMap['fat'] as num?)?.toDouble() ?? 0;
            final foodName = mealMap['name'] as String? ?? 'Meal';
            final mealType = mealMap['mealType'] as String? ?? 'Lunch';
            final loggedAt =
                DateTime.tryParse(mealMap['loggedAt'] as String? ?? '') ??
                    DateTime.now();

            final scan = ScanData(
              foodName: foodName,
              nutritionInfo:
                  'Calories: ${cal.round()} kcal, Protein: ${p.round()}g, Carbs: ${c.round()}g, Fat: ${f.round()}g',
              healthScore: mealMap['healthScore'] as String? ?? 'Good',
              recommendations: mealMap['recommendations'] as String? ?? '',
              vitaminsAndMinerals: const [],
              imagePath: mealMap['imageUrl'] as String? ?? '',
              timestamp: loggedAt,
              novaGroup: (mealMap['novaGroup'] as num?)?.toInt() ?? 1,
            );

            final entry = LoggedFoodEntry(
              scanData: scan,
              id: mealMap['id'] as String? ??
                  loggedAt.millisecondsSinceEpoch.toString(),
              timestamp: loggedAt,
              parsedNutrition: ParsedNutritionValues(
                  calories: cal, protein: p, carbs: c, fat: f),
              mealType: mealType,
            );

            _history.add(entry);
            await _storageService.saveToHistory(entry);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _loadNutritionTipsInternal() async {
    try {
      _nutritionTips =
          await _storageService.getNutritionTips(forceRefresh: false);
    } catch (e) {
      debugPrint('Error loading tips: $e');
    }
  }

  void _loadInitialMealPlanAndGrocery() {
    _mealPlan = MealPlannerService.getDefaultMealPlan();
    _groceryList = MealPlannerService.generateGroceryList(_mealPlan);
  }

  // --- Favorites Management ---
  bool isFavorite(String foodName) {
    return _favorites.any((f) =>
        f.name.toLowerCase() == foodName.toLowerCase() ||
        f.scanData.foodName.toLowerCase() == foodName.toLowerCase());
  }

  void toggleFavorite(ScanData scanData) {
    final existingIndex = _favorites.indexWhere((f) =>
        f.name.toLowerCase() == scanData.foodName.toLowerCase() ||
        f.scanData.foodName.toLowerCase() == scanData.foodName.toLowerCase());

    if (existingIndex >= 0) {
      _favorites.removeAt(existingIndex);
    } else {
      final caloriesMatch =
          RegExp(r'calories:\s*(\d+(?:\.\d+)?)', caseSensitive: false)
              .firstMatch(scanData.nutritionInfo);
      final proteinMatch =
          RegExp(r'protein:\s*(\d+(?:\.\d+)?)', caseSensitive: false)
              .firstMatch(scanData.nutritionInfo);
      final carbsMatch =
          RegExp(r'carbs?:\s*(\d+(?:\.\d+)?)', caseSensitive: false)
              .firstMatch(scanData.nutritionInfo);
      final fatMatch = RegExp(r'fat:\s*(\d+(?:\.\d+)?)', caseSensitive: false)
          .firstMatch(scanData.nutritionInfo);

      _favorites.insert(
        0,
        FavoriteMeal(
          id: 'fav_${DateTime.now().millisecondsSinceEpoch}',
          name: scanData.foodName,
          subtitle:
              'Nutri-Score ${scanData.healthScore.split('-').first.trim()}',
          calories: double.tryParse(caloriesMatch?.group(1) ?? '250') ?? 250,
          protein: double.tryParse(proteinMatch?.group(1) ?? '15') ?? 15,
          carbs: double.tryParse(carbsMatch?.group(1) ?? '25') ?? 25,
          fat: double.tryParse(fatMatch?.group(1) ?? '8') ?? 8,
          scanData: scanData,
        ),
      );
    }
    notifyListeners();

    try {
      SharedPreferences.getInstance().then((prefs) {
        final favsJson = _favorites
            .map((fav) => json.encode({
                  'name': fav.name,
                  'nutritionInfo': fav.nutritionInfo,
                  'healthScore': fav.scanData.healthScore,
                  'recommendations': fav.scanData.recommendations,
                  'ingredients': fav.scanData.ingredients,
                  'mealType': fav.defaultMealType,
                }))
            .toList();
        prefs.setStringList('user_favorites_v1', favsJson);
      });
    } catch (_) {}
  }

  Future<void> logFavoriteMeal(FavoriteMeal fav,
      {String mealType = 'Snack'}) async {
    final entry = LoggedFoodEntry(
      scanData: fav.scanData,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      parsedNutrition: ParsedNutritionValues(
        calories: fav.calories,
        protein: fav.protein,
        carbs: fav.carbs,
        fat: fav.fat,
      ),
      mealType: mealType,
    );
    await addToHistory(entry);
  }

  // --- Multi-Item Meal Basket ---
  int get basketTotalItems => _mealBasket.length;
  double get basketTotalCalories {
    double total = 0;
    for (final item in _mealBasket) {
      final caloriesMatch = RegExp(
                  r'(?:calories?|cal|energy|kcal):\s*(\d+(?:\.\d+)?)',
                  caseSensitive: false)
              .firstMatch(item.nutritionInfo) ??
          RegExp(r'(\d+(?:\.\d+)?)\s*(?:kcal|calories)', caseSensitive: false)
              .firstMatch(item.nutritionInfo);
      total += double.tryParse(caloriesMatch?.group(1) ?? '250') ?? 250;
    }
    return total;
  }

  void addToBasket(ScanData item,
      [ParsedNutritionValues? nutrition, String? mealType]) {
    _mealBasket.add(item);
    notifyListeners();
  }

  void removeFromBasket(int index) {
    if (index >= 0 && index < _mealBasket.length) {
      _mealBasket.removeAt(index);
      notifyListeners();
    }
  }

  void clearBasket() {
    _mealBasket.clear();
    notifyListeners();
  }

  Future<void> logEntireBasket([String mealType = 'Lunch']) async {
    for (final item in _mealBasket) {
      final caloriesMatch =
          RegExp(r'calories:\s*(\d+(?:\.\d+)?)', caseSensitive: false)
              .firstMatch(item.nutritionInfo);
      final proteinMatch =
          RegExp(r'protein:\s*(\d+(?:\.\d+)?)', caseSensitive: false)
              .firstMatch(item.nutritionInfo);
      final carbsMatch =
          RegExp(r'carbs?:\s*(\d+(?:\.\d+)?)', caseSensitive: false)
              .firstMatch(item.nutritionInfo);
      final fatMatch = RegExp(r'fat:\s*(\d+(?:\.\d+)?)', caseSensitive: false)
          .firstMatch(item.nutritionInfo);

      final entry = LoggedFoodEntry(
        scanData: item,
        id: '${DateTime.now().millisecondsSinceEpoch}_${item.id}',
        timestamp: DateTime.now(),
        parsedNutrition: ParsedNutritionValues(
          calories: double.tryParse(caloriesMatch?.group(1) ?? '200') ?? 200,
          protein: double.tryParse(proteinMatch?.group(1) ?? '12') ?? 12,
          carbs: double.tryParse(carbsMatch?.group(1) ?? '20') ?? 20,
          fat: double.tryParse(fatMatch?.group(1) ?? '6') ?? 6,
        ),
        mealType: mealType,
      );
      await addToHistory(entry);
    }
    _mealBasket.clear();
    notifyListeners();
  }

  // --- AI Meal Planner & Grocery ---
  Future<void> generateNewMealPlan(
      {String dietaryStyle = 'Balanced High-Protein'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _mealPlan = await MealPlannerService.generateMealPlan(
        targetCalories: _calorieTarget,
        targetProtein: _proteinTarget,
        dietaryStyle: dietaryStyle,
      );
      _groceryList = MealPlannerService.generateGroceryList(_mealPlan);
    } catch (e) {
      debugPrint('Error generating meal plan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleGroceryItem(String id) {
    final index = _groceryList.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _groceryList[index].isChecked = !_groceryList[index].isChecked;
      notifyListeners();
    }
  }

  void addCustomGroceryItem(String name, String category) {
    _groceryList.insert(
      0,
      GroceryItem(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        category: category,
      ),
    );
    notifyListeners();
  }

  void clearCheckedGroceryItems() {
    _groceryList.removeWhere((item) => item.isChecked);
    notifyListeners();
  }

  void addGroceryItem(String name, String aisle) =>
      addCustomGroceryItem(name, aisle);

  void clearCompletedGrocery() => clearCheckedGroceryItems();

  // --- Health Sync ---
  void toggleHealthSync([bool? value]) {
    _isHealthSyncEnabled = value ?? !_isHealthSyncEnabled;
    notifyListeners();
  }

  void syncWithHealthConnect() {
    notifyListeners();
  }

  Future<void> reloadHydrationAndTargets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey =
          'water_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}';
      _waterIntakeMl = prefs.getInt(todayKey) ?? 1250;
      _calorieTarget = prefs.getDouble('target_calories') ?? 2100;
      _proteinTarget = prefs.getDouble('target_protein') ?? 140;
      _carbsTarget = prefs.getDouble('target_carbs') ?? 220;
      _fatTarget = prefs.getDouble('target_fat') ?? 65;

      _userAge = prefs.getInt('user_age') ?? 26;
      _userGender = prefs.getString('user_gender') ?? 'Female';
      _userHeightCm = prefs.getDouble('user_height_cm') ?? 170.0;
      _userWeightKg = prefs.getDouble('user_weight_kg') ?? 65.0;
      _userActivityLevel =
          prefs.getString('user_activity_level') ?? 'Moderately Active';
      _userGoal = prefs.getString('user_goal') ?? 'Healthy Lifestyle';

      final themeModeStr = prefs.getString('app_theme_mode') ?? 'light';
      if (themeModeStr == 'dark') {
        _themeMode = ThemeMode.dark;
        AppTheme.setDarkMode(true);
      } else if (themeModeStr == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.light;
        AppTheme.setDarkMode(false);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading hydration and targets: $e');
    }
  }

  // Recommended Targets Calculator
  static Map<String, double> calculateRecommendedTargets({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String goal,
  }) {
    final isMale = gender.toLowerCase() == 'male';
    // Mifflin-St Jeor Formula
    double bmr =
        (10 * weightKg) + (6.25 * heightCm) - (5 * age) + (isMale ? 5 : -161);

    double activityMultiplier;
    switch (activityLevel) {
      case 'Sedentary':
        activityMultiplier = 1.2;
        break;
      case 'Lightly Active':
        activityMultiplier = 1.375;
        break;
      case 'Moderately Active':
        activityMultiplier = 1.55;
        break;
      case 'Very Active':
        activityMultiplier = 1.725;
        break;
      case 'Extra Active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55;
        break;
    }

    double tdee = bmr * activityMultiplier;

    double calorieTarget;
    double proteinTarget;
    double carbsTarget;
    double fatTarget;

    if (goal.contains('Loss')) {
      calorieTarget = (tdee - 450).clamp(1200.0, 4500.0);
      proteinTarget = (weightKg * 2.0).clamp(80.0, 240.0);
      fatTarget = (calorieTarget * 0.25 / 9.0).clamp(40.0, 110.0);
      carbsTarget =
          ((calorieTarget - (proteinTarget * 4) - (fatTarget * 9)) / 4.0)
              .clamp(50.0, 400.0);
    } else if (goal.contains('Muscle')) {
      calorieTarget = (tdee + 350).clamp(1600.0, 5000.0);
      proteinTarget = (weightKg * 2.2).clamp(100.0, 260.0);
      fatTarget = (calorieTarget * 0.25 / 9.0).clamp(50.0, 130.0);
      carbsTarget =
          ((calorieTarget - (proteinTarget * 4) - (fatTarget * 9)) / 4.0)
              .clamp(100.0, 500.0);
    } else if (goal.contains('Keto')) {
      calorieTarget = (tdee - 200).clamp(1300.0, 4000.0);
      proteinTarget = (weightKg * 1.8).clamp(90.0, 220.0);
      carbsTarget = 30.0;
      fatTarget =
          ((calorieTarget - (proteinTarget * 4) - (carbsTarget * 4)) / 9.0)
              .clamp(70.0, 200.0);
    } else {
      calorieTarget = tdee.clamp(1400.0, 4500.0);
      proteinTarget = (weightKg * 1.6).clamp(80.0, 220.0);
      fatTarget = (calorieTarget * 0.28 / 9.0).clamp(45.0, 120.0);
      carbsTarget =
          ((calorieTarget - (proteinTarget * 4) - (fatTarget * 9)) / 4.0)
              .clamp(80.0, 450.0);
    }

    double waterMl = (weightKg * 35.0) + (activityMultiplier > 1.5 ? 500 : 250);
    waterMl = waterMl.clamp(1800.0, 4500.0);

    return {
      'calories': calorieTarget.roundToDouble(),
      'protein': proteinTarget.roundToDouble(),
      'carbs': carbsTarget.roundToDouble(),
      'fat': fatTarget.roundToDouble(),
      'water': waterMl.roundToDouble(),
    };
  }

  // Save User Profile & Custom/Calculated Targets
  Future<void> saveUserProfileAndTargets({
    required String name,
    required String email,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String goal,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    int? waterMl,
    String? photoPath,
  }) async {
    _userProfileName = name.trim().isEmpty ? 'Nutrition User' : name.trim();
    _userProfileEmail = email.trim();
    if (photoPath != null) {
      _userPhotoPath = photoPath;
    }
    _userAge = age;
    _userGender = gender;
    _userHeightCm = heightCm;
    _userWeightKg = weightKg;
    _userActivityLevel = activityLevel;
    _userGoal = goal;

    _calorieTarget = calories;
    _proteinTarget = protein;
    _carbsTarget = carbs;
    _fatTarget = fat;

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _userProfileName);
      await prefs.setString('user_email', _userProfileEmail);
      if (photoPath != null) {
        if (photoPath.isEmpty) {
          await prefs.remove('user_photo_path');
        } else {
          await prefs.setString('user_photo_path', photoPath);
        }
      }
      await prefs.setInt('user_age', age);
      await prefs.setString('user_gender', gender);
      await prefs.setDouble('user_height_cm', heightCm);
      await prefs.setDouble('user_weight_kg', weightKg);
      await prefs.setString('user_activity_level', activityLevel);
      await prefs.setString('user_goal', goal);

      await prefs.setDouble('target_calories', calories);
      await prefs.setDouble('target_protein', protein);
      await prefs.setDouble('target_carbs', carbs);
      await prefs.setDouble('target_fat', fat);
    } catch (e) {
      debugPrint('Error saving user profile and targets: $e');
    }
  }

  // Hydration Management
  Future<void> addWater(int amountMl) async {
    _waterIntakeMl = (_waterIntakeMl + amountMl).clamp(0, 5000);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey =
          'water_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}';
      await prefs.setInt(todayKey, _waterIntakeMl);

      // Sync hydration to backend API
      ApiClient().logHydration(amountMl).catchError((_) => null);
    } catch (e) {
      debugPrint('Error saving water: $e');
    }
  }

  Future<void> resetWater() async {
    _waterIntakeMl = 0;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey =
          'water_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}';
      await prefs.setInt(todayKey, 0);
    } catch (e) {
      debugPrint('Error resetting water: $e');
    }
  }

  // Target Settings
  Future<void> updateTargets({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) async {
    if (calories != null) _calorieTarget = calories;
    if (protein != null) _proteinTarget = protein;
    if (carbs != null) _carbsTarget = carbs;
    if (fat != null) _fatTarget = fat;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (calories != null) await prefs.setDouble('target_calories', calories);
      if (protein != null) await prefs.setDouble('target_protein', protein);
      if (carbs != null) await prefs.setDouble('target_carbs', carbs);
      if (fat != null) await prefs.setDouble('target_fat', fat);
    } catch (e) {
      debugPrint('Error saving targets: $e');
    }
  }

  // Navigation
  void setCurrentView(String view) {
    _currentView = view;
    notifyListeners();
  }

  // Loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Scan data management
  void setCurrentScanData(ScanData scanData) {
    _currentScanData = scanData;
    notifyListeners();
  }

  void clearCurrentScanData() {
    _currentScanData = null;
    notifyListeners();
  }

  // History management
  Future<void> loadHistory() async {
    await _loadHistoryInternal();
    notifyListeners();
  }

  Future<void> addToHistory(LoggedFoodEntry entry) async {
    try {
      await _storageService.saveToHistory(entry);
      _history.insert(0, entry);
      notifyListeners();

      // Normalize mealType for backend Zod enum: 'Breakfast' | 'Lunch' | 'Dinner' | 'Snack'
      String rawMealType = (entry.mealType ?? 'Snack').trim();
      String normalizedMealType = 'Snack';
      if (rawMealType.toLowerCase().contains('break')) {
        normalizedMealType = 'Breakfast';
      } else if (rawMealType.toLowerCase().contains('lunch')) {
        normalizedMealType = 'Lunch';
      } else if (rawMealType.toLowerCase().contains('din')) {
        normalizedMealType = 'Dinner';
      }

      // Sync to backend API
      final res = await ApiClient().createMeal({
        'name': entry.scanData.foodName,
        'mealType': normalizedMealType,
        'calories': entry.parsedNutrition.calories,
        'protein': entry.parsedNutrition.protein,
        'carbs': entry.parsedNutrition.carbs,
        'fat': entry.parsedNutrition.fat,
        'healthScore': entry.scanData.healthScore,
        'recommendations': entry.scanData.recommendations,
        'novaGroup': entry.scanData.novaGroup,
        'ingredients': entry.scanData.ingredients,
        'isAiEstimate': true,
        'userEdited': false,
        'loggedAt': entry.timestamp.toIso8601String(),
      });

      if (res != null && res['data'] != null && res['data']['id'] != null) {
        final backendId = res['data']['id'].toString();
        final idx = _history.indexWhere((e) => e.id == entry.id);
        if (idx >= 0) {
          final updatedEntry = LoggedFoodEntry(
            id: backendId,
            timestamp: entry.timestamp,
            mealType: entry.mealType,
            scanData: entry.scanData,
            parsedNutrition: entry.parsedNutrition,
          );
          _history[idx] = updatedEntry;
          await _storageService.saveToHistory(updatedEntry);
        }
      }
    } catch (e) {
      debugPrint('Error adding to history: $e');
    }
  }

  Future<void> removeFromHistory(String id) async {
    try {
      await _storageService.removeFromHistory(id);
      _history.removeWhere((entry) => entry.id == id);
      notifyListeners();

      // Delete from backend API
      ApiClient().deleteMeal(id).catchError((_) => false);
    } catch (e) {
      debugPrint('Error removing from history: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await _storageService.clearHistory();
      _history.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  // Nutrition tips management
  Future<void> loadPersonalizedTips() => loadNutritionTips();

  Future<void> loadNutritionTips({bool forceRefresh = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _nutritionTips =
          await _storageService.getNutritionTips(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('Error loading nutrition tips: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshNutritionTips() async {
    await loadNutritionTips(forceRefresh: true);
  }

  // Summary and statistics
  Map<String, double> getDailyNutritionSummary(DateTime date) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    final dayEntries = _history.where((entry) {
      return entry.timestamp.year == date.year &&
          entry.timestamp.month == date.month &&
          entry.timestamp.day == date.day;
    });

    for (final entry in dayEntries) {
      totalCalories += entry.parsedNutrition.calories;
      totalProtein += entry.parsedNutrition.protein;
      totalCarbs += entry.parsedNutrition.carbs;
      totalFat += entry.parsedNutrition.fat;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  List<LoggedFoodEntry> getEntriesForDate(DateTime date) {
    return _history.where((entry) {
      return entry.timestamp.year == date.year &&
          entry.timestamp.month == date.month &&
          entry.timestamp.day == date.day;
    }).toList();
  }

  List<LoggedFoodEntry> getEntriesForMeal(DateTime date, String mealType) {
    return _history.where((entry) {
      final isSameDay = entry.timestamp.year == date.year &&
          entry.timestamp.month == date.month &&
          entry.timestamp.day == date.day;
      final matchesMeal =
          (entry.mealType ?? 'Snack').toLowerCase() == mealType.toLowerCase();
      return isSameDay && matchesMeal;
    }).toList();
  }

  int getStreakDays() {
    if (_history.isEmpty) return 3;

    final uniqueDates = _history
        .map((e) =>
            DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (uniqueDates.isEmpty) return 3;

    int streak = 0;
    DateTime checkDate = uniqueDates.contains(today) ? today : yesterday;

    for (final date in uniqueDates) {
      if (date == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(checkDate)) {
        break;
      }
    }

    return streak == 0 ? 3 : streak;
  }

  Map<String, int> getMealTypeDistribution() {
    final distribution = <String, int>{};
    for (final entry in _history) {
      final mealType = entry.mealType ?? 'Unknown';
      distribution[mealType] = (distribution[mealType] ?? 0) + 1;
    }
    return distribution;
  }
}
