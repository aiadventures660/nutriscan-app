class VitaminMineral {
  final String name;
  final String amount;
  final String dailyValue;

  VitaminMineral({
    required this.name,
    required this.amount,
    required this.dailyValue,
  });

  factory VitaminMineral.fromJson(Map<String, dynamic> json) {
    return VitaminMineral(
      name: json['name'] ?? '',
      amount: json['amount'] ?? '',
      dailyValue: json['dailyValue'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'dailyValue': dailyValue,
    };
  }
}

class FoodAdditive {
  final String name;
  final String risk; // 'low', 'moderate', 'high'
  final String description;
  final String code;
  final String purpose;

  FoodAdditive({
    required this.name,
    required this.risk,
    required this.description,
    String? code,
    String? purpose,
  })  : code = code ?? '',
        purpose = purpose ?? description;

  String get riskLevel => risk;

  factory FoodAdditive.fromJson(Map<String, dynamic> json) {
    return FoodAdditive(
      name: json['name'] ?? '',
      risk: json['risk'] ?? 'low',
      description: json['description'] ?? '',
      code: json['code'] ?? '',
      purpose: json['purpose'] ?? json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'risk': risk,
      'description': description,
      'code': code,
      'purpose': purpose,
    };
  }
}

class ScanData {
  final String foodName;
  final String nutritionInfo;
  final String healthScore;
  final String recommendations;
  final List<VitaminMineral> vitaminsAndMinerals;
  final String imagePath;
  final DateTime timestamp;
  final String id;
  final int novaGroup; // 1: Unprocessed, 2: Culinary, 3: Processed, 4: Ultra-processed
  final List<FoodAdditive> additives;
  final List<String> allergens;
  final String? barcode;
  final bool isFavorite;
  final List<String> ingredients;
  final int itemCount; // Number of items detected in photo (e.g. 1 or 3 apples)
  final String unitName; // "apple", "banana", "egg", "slice", "piece", "serving"
  final String servingSize; // "1 medium piece (~180g)"
  final double unitWeightGrams; // Weight per unit in grams (e.g. 180.0)
  final String? singleItemNutrition; // Nutrition for exactly 1 item
  final String? totalDetectedNutrition; // Nutrition for all detected items combined

  ScanData({
    required this.foodName,
    required this.nutritionInfo,
    required this.healthScore,
    required this.recommendations,
    required this.vitaminsAndMinerals,
    required this.imagePath,
    DateTime? timestamp,
    String? id,
    this.ingredients = const [],
    this.novaGroup = 1,
    this.additives = const [],
    this.allergens = const [],
    this.barcode,
    this.isFavorite = false,
    this.itemCount = 1,
    this.unitName = 'piece',
    this.servingSize = '1 serving',
    this.unitWeightGrams = 100.0,
    this.singleItemNutrition,
    this.totalDetectedNutrition,
  })  : timestamp = timestamp ?? DateTime.now(),
        id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  ParsedNutritionValues get nutrition => singleItemParsedNutrition;

  ParsedNutritionValues get singleItemParsedNutrition {
    final raw = (singleItemNutrition != null && singleItemNutrition!.isNotEmpty)
        ? singleItemNutrition!
        : nutritionInfo;
    double cal = 0, p = 0, c = 0, f = 0;
    final calM = RegExp(r'(?:calories?|cal|energy|kcal):\s*(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(raw) ??
        RegExp(r'(\d+(?:\.\d+)?)\s*(?:kcal|calories)', caseSensitive: false).firstMatch(raw);
    if (calM != null) cal = double.tryParse(calM.group(1) ?? '0') ?? 0;
    final pM = RegExp(r'protein:\s*(\d+(?:\.\d+)?)g?', caseSensitive: false).firstMatch(raw);
    if (pM != null) p = double.tryParse(pM.group(1) ?? '0') ?? 0;
    final cM = RegExp(r'(?:carbohydrates?|carbs?):\s*(\d+(?:\.\d+)?)g?', caseSensitive: false).firstMatch(raw);
    if (cM != null) c = double.tryParse(cM.group(1) ?? '0') ?? 0;
    final fM = RegExp(r'(?:total\s+fat|fat):\s*(\d+(?:\.\d+)?)g?', caseSensitive: false).firstMatch(raw);
    if (fM != null) f = double.tryParse(fM.group(1) ?? '0') ?? 0;
    return ParsedNutritionValues(calories: cal, protein: p, carbs: c, fat: f);
  }

  factory ScanData.fromJson(Map<String, dynamic> json) {
    return ScanData(
      foodName: json['foodName'] ?? '',
      nutritionInfo: json['nutritionInfo'] ?? '',
      healthScore: json['healthScore'] ?? '',
      recommendations: json['recommendations'] ?? '',
      vitaminsAndMinerals: (json['vitaminsAndMinerals'] as List<dynamic>?)
              ?.map((item) => VitaminMineral.fromJson(item))
              .toList() ??
          [],
      imagePath: json['imagePath'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      id: json['id'] ?? '',
      novaGroup: json['novaGroup'] ?? 1,
      additives: (json['additives'] as List<dynamic>?)
              ?.map((item) => FoodAdditive.fromJson(item))
              .toList() ??
          [],
      allergens: (json['allergens'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      barcode: json['barcode'],
      isFavorite: json['isFavorite'] ?? false,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      itemCount: json['itemCount'] is int
          ? json['itemCount']
          : int.tryParse(json['itemCount']?.toString() ?? '1') ?? 1,
      unitName: json['unitName'] ?? 'piece',
      servingSize: json['servingSize'] ?? '1 serving',
      unitWeightGrams: (json['unitWeightGrams'] is num)
          ? (json['unitWeightGrams'] as num).toDouble()
          : double.tryParse(json['unitWeightGrams']?.toString() ?? '100') ?? 100.0,
      singleItemNutrition: json['singleItemNutrition'] ?? json['nutritionInfo'],
      totalDetectedNutrition: json['totalDetectedNutrition'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'nutritionInfo': nutritionInfo,
      'healthScore': healthScore,
      'recommendations': recommendations,
      'vitaminsAndMinerals':
          vitaminsAndMinerals.map((vm) => vm.toJson()).toList(),
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'id': id,
      'novaGroup': novaGroup,
      'additives': additives.map((a) => a.toJson()).toList(),
      'allergens': allergens,
      'barcode': barcode,
      'isFavorite': isFavorite,
      'ingredients': ingredients,
      'itemCount': itemCount,
      'unitName': unitName,
      'servingSize': servingSize,
      'unitWeightGrams': unitWeightGrams,
      'singleItemNutrition': singleItemNutrition,
      'totalDetectedNutrition': totalDetectedNutrition,
    };
  }

  ScanData copyWith({
    String? foodName,
    String? nutritionInfo,
    String? healthScore,
    String? recommendations,
    List<VitaminMineral>? vitaminsAndMinerals,
    String? imagePath,
    DateTime? timestamp,
    String? id,
    int? novaGroup,
    List<FoodAdditive>? additives,
    List<String>? allergens,
    String? barcode,
    bool? isFavorite,
    List<String>? ingredients,
    int? itemCount,
    String? unitName,
    String? servingSize,
    double? unitWeightGrams,
    String? singleItemNutrition,
    String? totalDetectedNutrition,
  }) {
    return ScanData(
      foodName: foodName ?? this.foodName,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      healthScore: healthScore ?? this.healthScore,
      recommendations: recommendations ?? this.recommendations,
      vitaminsAndMinerals: vitaminsAndMinerals ?? this.vitaminsAndMinerals,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
      id: id ?? this.id,
      novaGroup: novaGroup ?? this.novaGroup,
      additives: additives ?? this.additives,
      allergens: allergens ?? this.allergens,
      barcode: barcode ?? this.barcode,
      isFavorite: isFavorite ?? this.isFavorite,
      ingredients: ingredients ?? this.ingredients,
      itemCount: itemCount ?? this.itemCount,
      unitName: unitName ?? this.unitName,
      servingSize: servingSize ?? this.servingSize,
      unitWeightGrams: unitWeightGrams ?? this.unitWeightGrams,
      singleItemNutrition: singleItemNutrition ?? this.singleItemNutrition,
      totalDetectedNutrition: totalDetectedNutrition ?? this.totalDetectedNutrition,
    );
  }
}

class ParsedNutritionValues {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  ParsedNutritionValues({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory ParsedNutritionValues.fromJson(Map<String, dynamic> json) {
    return ParsedNutritionValues(
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class LoggedFoodEntry {
  final ScanData scanData;
  final String id;
  final DateTime timestamp;
  final ParsedNutritionValues parsedNutrition;
  final String? mealType;

  LoggedFoodEntry({
    required this.scanData,
    required this.id,
    required this.timestamp,
    required this.parsedNutrition,
    this.mealType,
  });

  factory LoggedFoodEntry.fromJson(Map<String, dynamic> json) {
    return LoggedFoodEntry(
      scanData: ScanData.fromJson(json['scanData']),
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      parsedNutrition: ParsedNutritionValues.fromJson(json['parsedNutrition']),
      mealType: json['mealType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scanData': scanData.toJson(),
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'parsedNutrition': parsedNutrition.toJson(),
      'mealType': mealType,
    };
  }
}

class FavoriteMeal {
  final String id;
  final String name;
  final String subtitle;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final ScanData scanData;

  FavoriteMeal({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.scanData,
  });

  String get foodName => name;
  String get defaultMealType => 'Breakfast';
  String get nutritionInfo => scanData.nutritionInfo;
  String get healthScore => scanData.healthScore;
  String get recommendations => scanData.recommendations;
  List<String> get ingredients => scanData.ingredients;
  List<VitaminMineral> get vitaminsAndMinerals => scanData.vitaminsAndMinerals;
  int get novaGroup => scanData.novaGroup;

  factory FavoriteMeal.fromSimple({
    required String foodName,
    required String nutritionInfo,
    required String healthScore,
    required String recommendations,
    required List<String> ingredients,
    List<VitaminMineral> vitaminsAndMinerals = const [],
    String defaultMealType = 'Breakfast',
    int novaGroup = 1,
  }) {
    double cal = 250, p = 15, c = 25, f = 8;
    final calM = RegExp(r'(\d+(?:\.\d+)?)\s*(?:kcal|calories)', caseSensitive: false).firstMatch(nutritionInfo);
    if (calM != null) cal = double.tryParse(calM.group(1) ?? '250') ?? 250;
    final pM = RegExp(r'(\d+(?:\.\d+)?)g?\s*protein', caseSensitive: false).firstMatch(nutritionInfo);
    if (pM != null) p = double.tryParse(pM.group(1) ?? '15') ?? 15;
    final cM = RegExp(r'(\d+(?:\.\d+)?)g?\s*carbs', caseSensitive: false).firstMatch(nutritionInfo);
    if (cM != null) c = double.tryParse(cM.group(1) ?? '25') ?? 25;
    final fM = RegExp(r'(\d+(?:\.\d+)?)g?\s*fat', caseSensitive: false).firstMatch(nutritionInfo);
    if (fM != null) f = double.tryParse(fM.group(1) ?? '8') ?? 8;

    final sd = ScanData(
      foodName: foodName,
      nutritionInfo: nutritionInfo,
      healthScore: healthScore,
      recommendations: recommendations,
      ingredients: ingredients,
      vitaminsAndMinerals: vitaminsAndMinerals,
      imagePath: '',
      novaGroup: novaGroup,
    );

    return FavoriteMeal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: foodName,
      subtitle: '$defaultMealType Favorite',
      calories: cal,
      protein: p,
      carbs: c,
      fat: f,
      scanData: sd,
    );
  }

  factory FavoriteMeal.fromJson(Map<String, dynamic> json) {
    return FavoriteMeal(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      subtitle: json['subtitle'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      scanData: ScanData.fromJson(json['scanData']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtitle': subtitle,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'scanData': scanData.toJson(),
    };
  }
}

class MealPlanItem {
  final String day;
  final String mealType;
  final String title;
  final String description;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<String> ingredients;
  final String prepTime;

  MealPlanItem({
    required this.day,
    required this.mealType,
    required this.title,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
    this.prepTime = '15 mins',
  });

  factory MealPlanItem.fromJson(Map<String, dynamic> json) {
    return MealPlanItem(
      day: json['day'] ?? 'Monday',
      mealType: json['mealType'] ?? 'Lunch',
      title: json['title'] ?? 'Nutritious Meal',
      description: json['description'] ?? '',
      calories: json['calories'] ?? 450,
      protein: json['protein'] ?? 30,
      carbs: json['carbs'] ?? 40,
      fat: json['fat'] ?? 15,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      prepTime: json['prepTime'] ?? '15 mins',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'mealType': mealType,
      'title': title,
      'description': description,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'ingredients': ingredients,
      'prepTime': prepTime,
    };
  }
}

class GroceryItem {
  final String id;
  final String name;
  final String category; // 'Produce', 'Dairy & Eggs', 'Protein', 'Pantry', 'Fats & Oils'
  final String quantity;
  bool isChecked;

  GroceryItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = '1 pack',
    this.isChecked = false,
  });

  String get aisle => category;
  bool get isCompleted => isChecked;
  set isCompleted(bool val) => isChecked = val;

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
      category: json['category'] ?? 'Pantry',
      quantity: json['quantity'] ?? '1 item',
      isChecked: json['isChecked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'isChecked': isChecked,
    };
  }
}

class FoodComparisonResult {
  final String summary;
  final String winner; // 'foodA', 'foodB', 'tie'
  final String proteinVerdict;
  final String sugarVerdict;
  final String processingVerdict;
  final String foodAName;
  final String foodBName;
  final double caloriesA;
  final double caloriesB;
  final double proteinA;
  final double proteinB;
  final double carbsA;
  final double carbsB;
  final double fatA;
  final double fatB;
  final int novaA;
  final int novaB;
  final List<String> keyAdvantagesA;
  final List<String> keyAdvantagesB;

  FoodComparisonResult({
    required this.summary,
    required this.winner,
    this.proteinVerdict = '',
    this.sugarVerdict = '',
    this.processingVerdict = '',
    this.foodAName = 'Food A',
    this.foodBName = 'Food B',
    this.caloriesA = 250,
    this.caloriesB = 220,
    this.proteinA = 20,
    this.proteinB = 15,
    this.carbsA = 25,
    this.carbsB = 30,
    this.fatA = 8,
    this.fatB = 6,
    this.novaA = 1,
    this.novaB = 2,
    this.keyAdvantagesA = const ['Higher protein density', 'Minimally processed whole food'],
    this.keyAdvantagesB = const ['Lower saturated fat', 'Clean nutrient balance'],
  });

  factory FoodComparisonResult.fromJson(Map<String, dynamic> json) {
    return FoodComparisonResult(
      summary: json['summary'] ?? '',
      winner: json['winner'] ?? 'foodA',
      proteinVerdict: json['proteinVerdict'] ?? '',
      sugarVerdict: json['sugarVerdict'] ?? '',
      processingVerdict: json['processingVerdict'] ?? '',
      foodAName: json['foodAName'] ?? 'Food A',
      foodBName: json['foodBName'] ?? 'Food B',
      caloriesA: (json['caloriesA'] ?? 250).toDouble(),
      caloriesB: (json['caloriesB'] ?? 220).toDouble(),
      proteinA: (json['proteinA'] ?? 20).toDouble(),
      proteinB: (json['proteinB'] ?? 15).toDouble(),
      carbsA: (json['carbsA'] ?? 25).toDouble(),
      carbsB: (json['carbsB'] ?? 30).toDouble(),
      fatA: (json['fatA'] ?? 8).toDouble(),
      fatB: (json['fatB'] ?? 6).toDouble(),
      novaA: json['novaA'] ?? 1,
      novaB: json['novaB'] ?? 2,
      keyAdvantagesA: (json['keyAdvantagesA'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const ['Higher protein density', 'Minimally processed whole food'],
      keyAdvantagesB: (json['keyAdvantagesB'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const ['Lower saturated fat', 'Clean nutrient balance'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'winner': winner,
      'proteinVerdict': proteinVerdict,
      'sugarVerdict': sugarVerdict,
      'processingVerdict': processingVerdict,
    };
  }
}

class NutritionTip {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;

  NutritionTip({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
  });

  factory NutritionTip.fromJson(Map<String, dynamic> json) {
    return NutritionTip(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
    };
  }
}

class OnboardingStep {
  final String imageUrl;
  final String title;

  OnboardingStep({
    required this.imageUrl,
    required this.title,
  });
}
