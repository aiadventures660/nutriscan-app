import { Request } from 'express';

export interface AuthenticatedUser {
  id: string; // Database internal UUID (from public.profiles)
  clerkUserId: string; // Verified Clerk User ID (e.g. user_2...)
  email: string;
  name?: string;
}

export interface AuthenticatedRequest extends Request {
  user?: AuthenticatedUser;
}

export interface UserProfile {
  id: string;
  clerkUserId: string;
  email: string;
  name?: string | null;
  profileImageUrl?: string | null;
  age?: number | null;
  gender?: 'male' | 'female' | 'other' | 'prefer_not_to_say' | null;
  heightCm?: number | null;
  weightKg?: number | null;
  activityLevel?: 'sedentary' | 'lightly_active' | 'moderately_active' | 'very_active' | 'extra_active' | null;
  goal?: 'healthy_lifestyle' | 'lose_weight' | 'build_muscle' | 'keto_low_carb' | 'maintain_weight' | null;
  targetCalories: number;
  targetProtein: number;
  targetCarbs: number;
  targetFat: number;
  targetWaterMl: number;
  streakDays: number;
  totalScans: number;
  dietaryRestrictions: string[];
  allergies: string[];
  healthConditions: string[];
  medications: string[];
  createdAt: string;
  updatedAt: string;
}

export interface UserPreferencesData {
  id?: string;
  userId?: string;
  notificationsEnabled: boolean;
  dailyReminders: boolean;
  reminderTime: string;
  units: string;
  language: string;
  dataAnalytics: boolean;
  aiSuggestions: boolean;
  theme: string;
}

export interface FoodAdditive {
  name: string;
  risk: 'low' | 'moderate' | 'high';
  description: string;
  code?: string;
  purpose?: string;
}

export interface VitaminMineral {
  name: string;
  amount: string;
  dailyValue: string;
}

export interface HealthierAlternative {
  foodName: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  reason: string;
}

export interface FoodAnalysisResult {
  foodName: string;
  itemCount: number;
  unitName: string;
  servingSize: string;
  unitWeightGrams: number;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber: number;
  sugar: number;
  sodium: number;
  healthScore: string;
  recommendations: string;
  novaGroup: number;
  ingredients: string[];
  additives: FoodAdditive[];
  allergens: string[];
  vitaminsAndMinerals: VitaminMineral[];
  healthierAlternatives: HealthierAlternative[];
  imageUrl?: string;
  isEstimate: boolean;
  disclaimer: string;
}

export interface MealRecord {
  id: string;
  userId: string;
  name: string;
  mealType: 'Breakfast' | 'Lunch' | 'Dinner' | 'Snack';
  imageUrl?: string | null;
  storagePath?: string | null;
  loggedAt: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber: number;
  sugar: number;
  sodium: number;
  healthScore?: string | null;
  recommendations?: string | null;
  novaGroup: number;
  barcode?: string | null;
  isFavorite: boolean;
  itemCount: number;
  unitName: string;
  servingSize: string;
  unitWeightGrams: number;
  ingredients: string[];
  additives: FoodAdditive[];
  allergens: string[];
  vitaminsMinerals: VitaminMineral[];
  isAiEstimate: boolean;
  userEdited: boolean;
  rawNutritionInfo?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface DailySummary {
  date: string;
  totalCalories: number;
  targetCalories: number;
  remainingCalories: number;
  calorieProgressPercent: number;
  totalProtein: number;
  targetProtein: number;
  proteinProgressPercent: number;
  totalCarbs: number;
  targetCarbs: number;
  carbsProgressPercent: number;
  totalFat: number;
  targetFat: number;
  fatProgressPercent: number;
  totalWaterMl: number;
  targetWaterMl: number;
  waterProgressPercent: number;
  streakDays: number;
  mealCount: number;
  mealsByType: {
    Breakfast: MealRecord[];
    Lunch: MealRecord[];
    Dinner: MealRecord[];
    Snack: MealRecord[];
  };
}
