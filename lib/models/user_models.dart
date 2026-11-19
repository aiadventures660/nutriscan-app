import 'package:flutter/material.dart';
import 'food_models.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final DateTime createdAt;
  final UserPreferences preferences;
  final HealthProfile healthProfile;
  final List<String> dietaryRestrictions;
  final List<String> allergies;
  final int streakDays;
  final int totalScans;
  final double? targetCalories;
  final double? targetProtein;
  final double? targetCarbs;
  final double? targetFat;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
    required this.preferences,
    required this.healthProfile,
    this.dietaryRestrictions = const [],
    this.allergies = const [],
    this.streakDays = 0,
    this.totalScans = 0,
    this.targetCalories,
    this.targetProtein,
    this.targetCarbs,
    this.targetFat,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      healthProfile: HealthProfile.fromJson(json['healthProfile'] ?? {}),
      dietaryRestrictions: List<String>.from(json['dietaryRestrictions'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      streakDays: json['streakDays'] ?? 0,
      totalScans: json['totalScans'] ?? 0,
      targetCalories: json['targetCalories']?.toDouble(),
      targetProtein: json['targetProtein']?.toDouble(),
      targetCarbs: json['targetCarbs']?.toDouble(),
      targetFat: json['targetFat']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'preferences': preferences.toJson(),
      'healthProfile': healthProfile.toJson(),
      'dietaryRestrictions': dietaryRestrictions,
      'allergies': allergies,
      'streakDays': streakDays,
      'totalScans': totalScans,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFat': targetFat,
    };
  }

  User copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    UserPreferences? preferences,
    HealthProfile? healthProfile,
    List<String>? dietaryRestrictions,
    List<String>? allergies,
    int? streakDays,
    int? totalScans,
    double? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      preferences: preferences ?? this.preferences,
      healthProfile: healthProfile ?? this.healthProfile,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      allergies: allergies ?? this.allergies,
      streakDays: streakDays ?? this.streakDays,
      totalScans: totalScans ?? this.totalScans,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
    );
  }
}

class UserPreferences {
  final bool notificationsEnabled;
  final bool dailyReminders;
  final TimeOfDay? reminderTime;
  final String units; // 'metric' or 'imperial'
  final String language;
  final bool dataAnalytics;
  final bool aiSuggestions;
  final String theme; // 'dark', 'light', 'system'

  UserPreferences({
    this.notificationsEnabled = true,
    this.dailyReminders = true,
    this.reminderTime,
    this.units = 'metric',
    this.language = 'en',
    this.dataAnalytics = true,
    this.aiSuggestions = true,
    this.theme = 'dark',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      dailyReminders: json['dailyReminders'] ?? true,
      reminderTime: json['reminderTime'] != null 
          ? TimeOfDay(
              hour: json['reminderTime']['hour'] ?? 8,
              minute: json['reminderTime']['minute'] ?? 0,
            )
          : null,
      units: json['units'] ?? 'metric',
      language: json['language'] ?? 'en',
      dataAnalytics: json['dataAnalytics'] ?? true,
      aiSuggestions: json['aiSuggestions'] ?? true,
      theme: json['theme'] ?? 'dark',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'dailyReminders': dailyReminders,
      'reminderTime': reminderTime != null 
          ? {'hour': reminderTime!.hour, 'minute': reminderTime!.minute}
          : null,
      'units': units,
      'language': language,
      'dataAnalytics': dataAnalytics,
      'aiSuggestions': aiSuggestions,
      'theme': theme,
    };
  }
}

class HealthProfile {
  final int? age;
  final String? gender; // 'male', 'female', 'other', 'prefer_not_to_say'
  final double? height; // in cm
  final double? weight; // in kg
  final String? activityLevel; // 'sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extra_active'
  final String? goal; // 'lose_weight', 'maintain_weight', 'gain_weight', 'build_muscle'
  final List<String> healthConditions;
  final List<String> medications;

  HealthProfile({
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.activityLevel,
    this.goal,
    this.healthConditions = const [],
    this.medications = const [],
  });

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    return HealthProfile(
      age: json['age'],
      gender: json['gender'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      activityLevel: json['activityLevel'],
      goal: json['goal'],
      healthConditions: List<String>.from(json['healthConditions'] ?? []),
      medications: List<String>.from(json['medications'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'goal': goal,
      'healthConditions': healthConditions,
      'medications': medications,
    };
  }

  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Unknown';
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal weight';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final DateTime unlockedAt;
  final int points;
  final String category; // 'scanning', 'nutrition', 'consistency', 'goals'

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.unlockedAt,
    this.points = 10,
    required this.category,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'] ?? 'emoji_events',
      unlockedAt: DateTime.parse(json['unlockedAt'] ?? DateTime.now().toIso8601String()),
      points: json['points'] ?? 10,
      category: json['category'] ?? 'scanning',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'unlockedAt': unlockedAt.toIso8601String(),
      'points': points,
      'category': category,
    };
  }
}

class Goal {
  final String id;
  final String title;
  final String description;
  final GoalType type;
  final double targetValue;
  final double currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final String unit;
  final String? iconName;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    this.unit = '',
    this.iconName,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: GoalType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => GoalType.custom,
      ),
      targetValue: (json['targetValue'] ?? 0).toDouble(),
      currentValue: (json['currentValue'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      isCompleted: json['isCompleted'] ?? false,
      unit: json['unit'] ?? '',
      iconName: json['iconName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCompleted': isCompleted,
      'unit': unit,
      'iconName': iconName,
    };
  }

  double get progressPercentage {
    if (targetValue <= 0) return 0;
    return (currentValue / targetValue * 100).clamp(0, 100);
  }

  int get daysRemaining {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }
}

enum GoalType {
  dailyCalories,
  dailyProtein,
  dailyCarbs,
  dailyFat,
  weeklyScans,
  waterIntake,
  exercise,
  weightLoss,
  weightGain,
  custom,
}

class WeeklyProgress {
  final DateTime weekStart;
  final Map<DateTime, DailyNutrition> dailyData;
  final double averageCalories;
  final double averageProtein;
  final double averageCarbs;
  final double averageFat;
  final int totalScans;

  WeeklyProgress({
    required this.weekStart,
    required this.dailyData,
    this.averageCalories = 0,
    this.averageProtein = 0,
    this.averageCarbs = 0,
    this.averageFat = 0,
    this.totalScans = 0,
  });

  factory WeeklyProgress.fromDailyEntries(DateTime weekStart, List<LoggedFoodEntry> entries) {
    final Map<DateTime, DailyNutrition> dailyData = {};
    
    for (final entry in entries) {
      final date = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      
      if (dailyData.containsKey(date)) {
        dailyData[date] = dailyData[date]!.addEntry(entry);
      } else {
        dailyData[date] = DailyNutrition.fromEntry(entry);
      }
    }

    final totalDays = dailyData.length;
    final totalCalories = dailyData.values.fold(0.0, (sum, day) => sum + day.totalCalories);
    final totalProtein = dailyData.values.fold(0.0, (sum, day) => sum + day.totalProtein);
    final totalCarbs = dailyData.values.fold(0.0, (sum, day) => sum + day.totalCarbs);
    final totalFat = dailyData.values.fold(0.0, (sum, day) => sum + day.totalFat);
    final totalScans = dailyData.values.fold(0, (sum, day) => sum + day.scanCount);

    return WeeklyProgress(
      weekStart: weekStart,
      dailyData: dailyData,
      averageCalories: totalDays > 0 ? totalCalories / totalDays : 0,
      averageProtein: totalDays > 0 ? totalProtein / totalDays : 0,
      averageCarbs: totalDays > 0 ? totalCarbs / totalDays : 0,
      averageFat: totalDays > 0 ? totalFat / totalDays : 0,
      totalScans: totalScans,
    );
  }
}

class DailyNutrition {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int scanCount;
  final List<LoggedFoodEntry> entries;

  DailyNutrition({
    required this.date,
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.scanCount = 0,
    this.entries = const [],
  });

  factory DailyNutrition.fromEntry(LoggedFoodEntry entry) {
    return DailyNutrition(
      date: DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day),
      totalCalories: entry.parsedNutrition.calories,
      totalProtein: entry.parsedNutrition.protein,
      totalCarbs: entry.parsedNutrition.carbs,
      totalFat: entry.parsedNutrition.fat,
      scanCount: 1,
      entries: [entry],
    );
  }

  DailyNutrition addEntry(LoggedFoodEntry entry) {
    return DailyNutrition(
      date: date,
      totalCalories: totalCalories + entry.parsedNutrition.calories,
      totalProtein: totalProtein + entry.parsedNutrition.protein,
      totalCarbs: totalCarbs + entry.parsedNutrition.carbs,
      totalFat: totalFat + entry.parsedNutrition.fat,
      scanCount: scanCount + 1,
      entries: [...entries, entry],
    );
  }
}
