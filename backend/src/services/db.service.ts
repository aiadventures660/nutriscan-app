import { randomUUID } from 'crypto';
import { getSupabase, isSupabaseConfigured } from '../config/supabase.js';
import { logger } from '../utils/logger.js';
import {
  UserProfile,
  UserPreferencesData,
  MealRecord,
  DailySummary,
  FoodAdditive,
  VitaminMineral,
} from '../types/index.js';

// In-memory store used when Supabase is not configured or fails over during local dev
class InMemoryStore {
  profiles = new Map<string, UserProfile>(); // id -> profile
  profilesByClerkId = new Map<string, string>(); // clerkUserId -> id
  preferences = new Map<string, UserPreferencesData>(); // userId -> prefs
  meals = new Map<string, MealRecord>(); // id -> meal
  hydrationLogs: Array<{ id: string; userId: string; amountMl: number; loggedAt: string }> = [];
  favoriteMeals = new Map<string, any>(); // id -> favorite
}

const memStore = new InMemoryStore();

export class DatabaseService {
  /**
   * Fetch profile by verified Clerk user ID
   */
  async getProfileByClerkId(clerkUserId: string): Promise<UserProfile | null> {
    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase()
          .from('profiles')
          .select('*')
          .eq('clerk_user_id', clerkUserId)
          .maybeSingle();

        if (error) {
          logger.warn('Supabase getProfileByClerkId error, falling back to memory store', { error });
        } else if (data) {
          return this.mapSupabaseProfile(data);
        }
      } catch (err) {
        logger.warn('Supabase query failed, falling back to memory store', { err });
      }
    }

    const profileId = memStore.profilesByClerkId.get(clerkUserId);
    if (!profileId) return null;
    return memStore.profiles.get(profileId) || null;
  }

  /**
   * Fetch profile by internal UUID
   */
  async getProfileById(id: string): Promise<UserProfile | null> {
    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase()
          .from('profiles')
          .select('*')
          .eq('id', id)
          .maybeSingle();

        if (error) {
          logger.warn('Supabase getProfileById error', { error });
        } else if (data) {
          return this.mapSupabaseProfile(data);
        }
      } catch (err) {
        logger.warn('Supabase query failed', { err });
      }
    }

    return memStore.profiles.get(id) || null;
  }

  /**
   * Create a new user profile associated with a verified Clerk user ID
   */
  async createProfile(data: {
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
    targetCalories?: number;
    targetProtein?: number;
    targetCarbs?: number;
    targetFat?: number;
    targetWaterMl?: number;
    dietaryRestrictions?: string[];
    allergies?: string[];
    healthConditions?: string[];
    medications?: string[];
  }): Promise<UserProfile> {
    const id = randomUUID();
    const now = new Date().toISOString();

    const profile: UserProfile = {
      id,
      clerkUserId: data.clerkUserId,
      email: data.email,
      name: data.name || null,
      profileImageUrl: data.profileImageUrl || null,
      age: data.age ?? null,
      gender: data.gender ?? null,
      heightCm: data.heightCm ?? null,
      weightKg: data.weightKg ?? null,
      activityLevel: data.activityLevel ?? null,
      goal: data.goal ?? null,
      targetCalories: data.targetCalories ?? 2000,
      targetProtein: data.targetProtein ?? 100,
      targetCarbs: data.targetCarbs ?? 250,
      targetFat: data.targetFat ?? 65,
      targetWaterMl: data.targetWaterMl ?? 2500,
      streakDays: 0,
      totalScans: 0,
      dietaryRestrictions: data.dietaryRestrictions || [],
      allergies: data.allergies || [],
      healthConditions: data.healthConditions || [],
      medications: data.medications || [],
      createdAt: now,
      updatedAt: now,
    };

    if (isSupabaseConfigured()) {
      try {
        const { data: inserted, error } = await getSupabase()
          .from('profiles')
          .insert({
            id: profile.id,
            clerk_user_id: profile.clerkUserId,
            email: profile.email,
            name: profile.name,
            profile_image_url: profile.profileImageUrl,
            age: profile.age,
            gender: profile.gender,
            height_cm: profile.heightCm,
            weight_kg: profile.weightKg,
            activity_level: profile.activityLevel,
            goal: profile.goal,
            target_calories: profile.targetCalories,
            target_protein: profile.targetProtein,
            target_carbs: profile.targetCarbs,
            target_fat: profile.targetFat,
            target_water_ml: profile.targetWaterMl,
            streak_days: profile.streakDays,
            total_scans: profile.totalScans,
            dietary_restrictions: profile.dietaryRestrictions,
            allergies: profile.allergies,
            health_conditions: profile.healthConditions,
            medications: profile.medications,
            created_at: profile.createdAt,
            updated_at: profile.updatedAt,
          })
          .select()
          .single();

        if (error) {
          if (error.code === '23505') {
            const existing = await this.getProfileByClerkId(data.clerkUserId);
            if (existing) return existing;
          }
          logger.warn('Supabase createProfile insert failed, saving in memory', { error });
        } else if (inserted) {
          // Also initialize default preferences
          await this.createUserPreferences(profile.id);
          return this.mapSupabaseProfile(inserted);
        }
      } catch (err) {
        logger.warn('Supabase createProfile exception', { err });
      }
    }

    // Fallback store
    memStore.profiles.set(profile.id, profile);
    memStore.profilesByClerkId.set(profile.clerkUserId, profile.id);
    await this.createUserPreferences(profile.id);
    return profile;
  }

  /**
   * Update an existing user profile
   */
  async updateProfile(id: string, updates: Partial<UserProfile>): Promise<UserProfile> {
    const existing = await this.getProfileById(id);
    if (!existing) {
      throw new Error(`Profile not found for ID: ${id}`);
    }

    const now = new Date().toISOString();
    const updated: UserProfile = {
      ...existing,
      ...updates,
      id: existing.id,
      clerkUserId: existing.clerkUserId,
      email: existing.email,
      updatedAt: now,
    };

    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase()
          .from('profiles')
          .update({
            name: updated.name,
            profile_image_url: updated.profileImageUrl,
            age: updated.age,
            gender: updated.gender,
            height_cm: updated.heightCm,
            weight_kg: updated.weightKg,
            activity_level: updated.activityLevel,
            goal: updated.goal,
            target_calories: updated.targetCalories,
            target_protein: updated.targetProtein,
            target_carbs: updated.targetCarbs,
            target_fat: updated.targetFat,
            target_water_ml: updated.targetWaterMl,
            streak_days: updated.streakDays,
            total_scans: updated.totalScans,
            dietary_restrictions: updated.dietaryRestrictions,
            allergies: updated.allergies,
            health_conditions: updated.healthConditions,
            medications: updated.medications,
            updated_at: now,
          })
          .eq('id', id)
          .select()
          .single();

        if (error) {
          logger.warn('Supabase updateProfile error', { error });
        } else if (data) {
          return this.mapSupabaseProfile(data);
        }
      } catch (err) {
        logger.warn('Supabase updateProfile exception', { err });
      }
    }

    memStore.profiles.set(id, updated);
    return updated;
  }

  /**
   * User Preferences CRUD
   */
  async getUserPreferences(userId: string): Promise<UserPreferencesData> {
    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase()
          .from('user_preferences')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

        if (!error && data) {
          return {
            id: data.id,
            userId: data.user_id,
            notificationsEnabled: data.notifications_enabled,
            dailyReminders: data.daily_reminders,
            reminderTime: data.reminder_time,
            units: data.units,
            language: data.language,
            dataAnalytics: data.data_analytics,
            aiSuggestions: data.ai_suggestions,
            theme: data.theme,
          };
        }
      } catch (err) {
        logger.warn('Supabase getUserPreferences failed', { err });
      }
    }

    let prefs = memStore.preferences.get(userId);
    if (!prefs) {
      prefs = {
        userId,
        notificationsEnabled: true,
        dailyReminders: true,
        reminderTime: '08:00',
        units: 'metric',
        language: 'en',
        dataAnalytics: true,
        aiSuggestions: true,
        theme: 'system',
      };
      memStore.preferences.set(userId, prefs);
    }
    return prefs;
  }

  async createUserPreferences(userId: string): Promise<UserPreferencesData> {
    const prefs: UserPreferencesData = {
      id: randomUUID(),
      userId,
      notificationsEnabled: true,
      dailyReminders: true,
      reminderTime: '08:00',
      units: 'metric',
      language: 'en',
      dataAnalytics: true,
      aiSuggestions: true,
      theme: 'system',
    };

    if (isSupabaseConfigured()) {
      try {
        await getSupabase().from('user_preferences').insert({
          id: prefs.id,
          user_id: userId,
          notifications_enabled: prefs.notificationsEnabled,
          daily_reminders: prefs.dailyReminders,
          reminder_time: prefs.reminderTime,
          units: prefs.units,
          language: prefs.language,
          data_analytics: prefs.dataAnalytics,
          ai_suggestions: prefs.aiSuggestions,
          theme: prefs.theme,
        });
      } catch (err) {
        logger.warn('Supabase createUserPreferences failed', { err });
      }
    }

    memStore.preferences.set(userId, prefs);
    return prefs;
  }

  async updateUserPreferences(userId: string, updates: Partial<UserPreferencesData>): Promise<UserPreferencesData> {
    const current = await this.getUserPreferences(userId);
    const updated: UserPreferencesData = {
      ...current,
      ...updates,
      userId,
    };

    if (isSupabaseConfigured()) {
      try {
        await getSupabase()
          .from('user_preferences')
          .update({
            notifications_enabled: updated.notificationsEnabled,
            daily_reminders: updated.dailyReminders,
            reminder_time: updated.reminderTime,
            units: updated.units,
            language: updated.language,
            data_analytics: updated.dataAnalytics,
            ai_suggestions: updated.aiSuggestions,
            theme: updated.theme,
            updated_at: new Date().toISOString(),
          })
          .eq('user_id', userId);
      } catch (err) {
        logger.warn('Supabase updateUserPreferences error', { err });
      }
    }

    memStore.preferences.set(userId, updated);
    return updated;
  }

  /**
   * MEAL CRUD OPERATIONS
   */
  async createMeal(userId: string, data: Partial<MealRecord>): Promise<MealRecord> {
    const id = randomUUID();
    const now = new Date().toISOString();

    const meal: MealRecord = {
      id,
      userId,
      name: data.name || 'Unnamed Food',
      mealType: data.mealType || 'Lunch',
      imageUrl: data.imageUrl || null,
      storagePath: data.storagePath || null,
      loggedAt: data.loggedAt || now,
      calories: Number(data.calories || 0),
      protein: Number(data.protein || 0),
      carbs: Number(data.carbs || 0),
      fat: Number(data.fat || 0),
      fiber: Number(data.fiber || 0),
      sugar: Number(data.sugar || 0),
      sodium: Number(data.sodium || 0),
      healthScore: data.healthScore || 'Good',
      recommendations: data.recommendations || null,
      novaGroup: data.novaGroup || 1,
      barcode: data.barcode || null,
      isFavorite: !!data.isFavorite,
      itemCount: data.itemCount || 1,
      unitName: data.unitName || 'serving',
      servingSize: data.servingSize || '1 serving',
      unitWeightGrams: data.unitWeightGrams || 100,
      ingredients: data.ingredients || [],
      additives: data.additives || [],
      allergens: data.allergens || [],
      vitaminsMinerals: data.vitaminsMinerals || [],
      isAiEstimate: data.isAiEstimate !== undefined ? data.isAiEstimate : true,
      userEdited: !!data.userEdited,
      rawNutritionInfo: data.rawNutritionInfo || null,
      createdAt: now,
      updatedAt: now,
    };

    if (isSupabaseConfigured()) {
      try {
        const { data: inserted, error } = await getSupabase()
          .from('meals')
          .insert({
            id: meal.id,
            user_id: meal.userId,
            name: meal.name,
            meal_type: meal.mealType,
            image_url: meal.imageUrl,
            storage_path: meal.storagePath,
            logged_at: meal.loggedAt,
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat,
            fiber: meal.fiber,
            sugar: meal.sugar,
            sodium: meal.sodium,
            health_score: meal.healthScore,
            recommendations: meal.recommendations,
            nova_group: meal.novaGroup,
            barcode: meal.barcode,
            is_favorite: meal.isFavorite,
            item_count: meal.itemCount,
            unit_name: meal.unitName,
            serving_size: meal.servingSize,
            unit_weight_grams: meal.unitWeightGrams,
            ingredients: meal.ingredients,
            additives: meal.additives,
            allergens: meal.allergens,
            vitamins_minerals: meal.vitaminsMinerals,
            is_ai_estimate: meal.isAiEstimate,
            user_edited: meal.userEdited,
            raw_nutrition_info: meal.rawNutritionInfo,
            created_at: meal.createdAt,
            updated_at: meal.updatedAt,
          })
          .select()
          .single();

        if (error) {
          logger.warn('Supabase createMeal insert error', { error });
        } else if (inserted) {
          await this.incrementTotalScans(userId);
          return this.mapSupabaseMeal(inserted);
        }
      } catch (err) {
        logger.warn('Supabase createMeal exception', { err });
      }
    }

    memStore.meals.set(meal.id, meal);
    await this.incrementTotalScans(userId);
    return meal;
  }

  async getMealById(userId: string, mealId: string): Promise<MealRecord | null> {
    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase()
          .from('meals')
          .select('*')
          .eq('id', mealId)
          .eq('user_id', userId)
          .maybeSingle();

        if (!error && data) {
          return this.mapSupabaseMeal(data);
        }
      } catch (err) {
        logger.warn('Supabase getMealById exception', { err });
      }
    }

    const meal = memStore.meals.get(mealId);
    if (!meal || meal.userId !== userId) return null;
    return meal;
  }

  async getMeals(
    userId: string,
    options: {
      page?: number;
      limit?: number;
      mealType?: string;
      search?: string;
      startDate?: string;
      endDate?: string;
    } = {}
  ): Promise<{ meals: MealRecord[]; total: number; page: number; limit: number }> {
    const page = Math.max(1, options.page || 1);
    const limit = Math.min(100, Math.max(1, options.limit || 20));
    const offset = (page - 1) * limit;

    if (isSupabaseConfigured()) {
      try {
        let query = getSupabase()
          .from('meals')
          .select('*', { count: 'exact' })
          .eq('user_id', userId);

        if (options.mealType) {
          query = query.eq('meal_type', options.mealType);
        }
        if (options.search) {
          query = query.ilike('name', `%${options.search}%`);
        }
        if (options.startDate) {
          query = query.gte('logged_at', options.startDate);
        }
        if (options.endDate) {
          query = query.lte('logged_at', options.endDate);
        }

        query = query.order('logged_at', { ascending: false }).range(offset, offset + limit - 1);

        const { data, count, error } = await query;
        if (!error && data) {
          return {
            meals: data.map(this.mapSupabaseMeal),
            total: count || 0,
            page,
            limit,
          };
        }
      } catch (err) {
        logger.warn('Supabase getMeals exception', { err });
      }
    }

    // In-memory filter
    let all = Array.from(memStore.meals.values()).filter((m) => m.userId === userId);

    if (options.mealType) {
      all = all.filter((m) => m.mealType.toLowerCase() === options.mealType!.toLowerCase());
    }
    if (options.search) {
      const q = options.search.toLowerCase();
      all = all.filter((m) => m.name.toLowerCase().includes(q));
    }
    if (options.startDate) {
      all = all.filter((m) => new Date(m.loggedAt) >= new Date(options.startDate!));
    }
    if (options.endDate) {
      all = all.filter((m) => new Date(m.loggedAt) <= new Date(options.endDate!));
    }

    all.sort((a, b) => new Date(b.loggedAt).getTime() - new Date(a.loggedAt).getTime());

    const paginated = all.slice(offset, offset + limit);
    return {
      meals: paginated,
      total: all.length,
      page,
      limit,
    };
  }

  async updateMeal(userId: string, mealId: string, updates: Partial<MealRecord>): Promise<MealRecord | null> {
    const existing = await this.getMealById(userId, mealId);
    if (!existing) {
      return null;
    }

    const now = new Date().toISOString();
    const updated: MealRecord = {
      ...existing,
      ...updates,
      id: existing.id,
      userId: existing.userId,
      userEdited: true, // Flag as user-edited when modified
      updatedAt: now,
    };

    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase()
          .from('meals')
          .update({
            name: updated.name,
            meal_type: updated.mealType,
            calories: updated.calories,
            protein: updated.protein,
            carbs: updated.carbs,
            fat: updated.fat,
            fiber: updated.fiber,
            sugar: updated.sugar,
            sodium: updated.sodium,
            health_score: updated.healthScore,
            recommendations: updated.recommendations,
            nova_group: updated.novaGroup,
            is_favorite: updated.isFavorite,
            item_count: updated.itemCount,
            unit_name: updated.unitName,
            serving_size: updated.servingSize,
            unit_weight_grams: updated.unitWeightGrams,
            ingredients: updated.ingredients,
            additives: updated.additives,
            allergens: updated.allergens,
            vitamins_minerals: updated.vitaminsMinerals,
            user_edited: true,
            updated_at: now,
          })
          .eq('id', mealId)
          .eq('user_id', userId)
          .select()
          .single();

        if (!error && data) {
          return this.mapSupabaseMeal(data);
        }
      } catch (err) {
        logger.warn('Supabase updateMeal exception', { err });
      }
    }

    memStore.meals.set(mealId, updated);
    return updated;
  }

  async deleteMeal(userId: string, mealId: string): Promise<boolean> {
    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase()
          .from('meals')
          .delete()
          .eq('id', mealId)
          .eq('user_id', userId)
          .select('id');

        if (!error) return Array.isArray(data) && data.length > 0;
      } catch (err) {
        logger.warn('Supabase deleteMeal error', { err });
      }
    }

    const meal = memStore.meals.get(mealId);
    if (meal && meal.userId === userId) {
      memStore.meals.delete(mealId);
      return true;
    }
    return false;
  }

  /**
   * HYDRATION LOGGING
   */
  async logHydration(userId: string, amountMl: number): Promise<{ id: string; amountMl: number; loggedAt: string }> {
    const id = randomUUID();
    const loggedAt = new Date().toISOString();

    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase()
          .from('hydration_logs')
          .insert({
            id,
            user_id: userId,
            amount_ml: amountMl,
            logged_at: loggedAt,
          })
          .select()
          .single();

        if (!error && data) {
          return { id: data.id, amountMl: data.amount_ml, loggedAt: data.logged_at };
        }
      } catch (err) {
        logger.warn('Supabase logHydration exception', { err });
      }
    }

    const entry = { id, userId, amountMl, loggedAt };
    memStore.hydrationLogs.push(entry);
    return { id, amountMl, loggedAt };
  }

  async getHydrationForDate(userId: string, dateStr: string): Promise<number> {
    const dayStart = new Date(dateStr);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(dateStr);
    dayEnd.setHours(23, 59, 59, 999);

    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase()
          .from('hydration_logs')
          .select('amount_ml')
          .eq('user_id', userId)
          .gte('logged_at', dayStart.toISOString())
          .lte('logged_at', dayEnd.toISOString());

        if (!error && data) {
          return data.reduce((sum, item) => sum + (item.amount_ml || 0), 0);
        }
      } catch (err) {
        logger.warn('Supabase getHydrationForDate exception', { err });
      }
    }

    return memStore.hydrationLogs
      .filter((h) => h.userId === userId && new Date(h.loggedAt) >= dayStart && new Date(h.loggedAt) <= dayEnd)
      .reduce((sum, h) => sum + h.amountMl, 0);
  }

  /**
   * FAVORITE MEALS
   */
  async getFavoriteMeals(userId: string): Promise<any[]> {
    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase()
          .from('favorite_meals')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', { ascending: false });

        if (!error && data) {
          return data;
        }
      } catch (err) {
        logger.warn('Supabase getFavoriteMeals exception', { err });
      }
    }

    return Array.from(memStore.favoriteMeals.values()).filter((f) => f.userId === userId);
  }

  async addFavoriteMeal(userId: string, meal: MealRecord): Promise<any> {
    const id = randomUUID();
    const fav = {
      id,
      userId,
      name: meal.name,
      subtitle: `${meal.calories} kcal • ${meal.protein}g protein`,
      calories: meal.calories,
      protein: meal.protein,
      carbs: meal.carbs,
      fat: meal.fat,
      mealData: meal,
      createdAt: new Date().toISOString(),
    };

    if (isSupabaseConfigured()) {
      try {
        await getSupabase().from('favorite_meals').insert({
          id: fav.id,
          user_id: fav.userId,
          name: fav.name,
          subtitle: fav.subtitle,
          calories: fav.calories,
          protein: fav.protein,
          carbs: fav.carbs,
          fat: fav.fat,
          meal_data: fav.mealData,
          created_at: fav.createdAt,
        });
      } catch (err) {
        logger.warn('Supabase addFavoriteMeal exception', { err });
      }
    }

    memStore.favoriteMeals.set(id, fav);
    return fav;
  }

  async removeFavoriteMeal(userId: string, favoriteId: string): Promise<boolean> {
    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase()
          .from('favorite_meals')
          .delete()
          .eq('id', favoriteId)
          .eq('user_id', userId)
          .select('id');

        if (!error) return Array.isArray(data) && data.length > 0;
      } catch (err) {
        logger.warn('Supabase removeFavoriteMeal exception', { err });
      }
    }

    const fav = memStore.favoriteMeals.get(favoriteId);
    if (fav && fav.userId === userId) {
      memStore.favoriteMeals.delete(favoriteId);
      return true;
    }
    return false;
  }

  /**
   * DASHBOARD AND PROGRESS CALCULATION
   */
  async getDailySummary(userId: string, dateStr: string): Promise<DailySummary> {
    const profile = await this.getProfileById(userId);
    const targetCalories = profile?.targetCalories || 2000;
    const targetProtein = profile?.targetProtein || 100;
    const targetCarbs = profile?.targetCarbs || 250;
    const targetFat = profile?.targetFat || 65;
    const targetWaterMl = profile?.targetWaterMl || 2500;
    const streakDays = profile?.streakDays || 0;

    const dayStart = new Date(dateStr);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(dateStr);
    dayEnd.setHours(23, 59, 59, 999);

    const { meals } = await this.getMeals(userId, {
      startDate: dayStart.toISOString(),
      endDate: dayEnd.toISOString(),
      limit: 100,
    });

    const totalWaterMl = await this.getHydrationForDate(userId, dateStr);

    let totalCalories = 0;
    let totalProtein = 0;
    let totalCarbs = 0;
    let totalFat = 0;

    const mealsByType: DailySummary['mealsByType'] = {
      Breakfast: [],
      Lunch: [],
      Dinner: [],
      Snack: [],
    };

    for (const m of meals) {
      totalCalories += m.calories;
      totalProtein += m.protein;
      totalCarbs += m.carbs;
      totalFat += m.fat;

      if (mealsByType[m.mealType]) {
        mealsByType[m.mealType].push(m);
      } else {
        mealsByType.Snack.push(m);
      }
    }

    return {
      date: dateStr,
      totalCalories: Math.round(totalCalories),
      targetCalories,
      remainingCalories: Math.max(0, Math.round(targetCalories - totalCalories)),
      calorieProgressPercent: Math.min(1.0, totalCalories / (targetCalories || 1)),
      totalProtein: Math.round(totalProtein),
      targetProtein,
      proteinProgressPercent: Math.min(1.0, totalProtein / (targetProtein || 1)),
      totalCarbs: Math.round(totalCarbs),
      targetCarbs,
      carbsProgressPercent: Math.min(1.0, totalCarbs / (targetCarbs || 1)),
      totalFat: Math.round(totalFat),
      targetFat,
      fatProgressPercent: Math.min(1.0, totalFat / (targetFat || 1)),
      totalWaterMl,
      targetWaterMl,
      waterProgressPercent: Math.min(1.0, totalWaterMl / (targetWaterMl || 1)),
      streakDays,
      mealCount: meals.length,
      mealsByType,
    };
  }

  async getWeeklySummary(userId: string, endDateStr: string): Promise<DailySummary[]> {
    const end = new Date(endDateStr);
    const summaries: DailySummary[] = [];

    for (let i = 6; i >= 0; i--) {
      const d = new Date(end);
      d.setDate(d.getDate() - i);
      const iso = d.toISOString().split('T')[0];
      const s = await this.getDailySummary(userId, iso);
      summaries.push(s);
    }

    return summaries;
  }

  /**
   * USER ACCOUNT EXPORT AND DELETION (GDPR Compliance)
   */
  async exportUserData(userId: string): Promise<any> {
    const profile = await this.getProfileById(userId);
    const preferences = await this.getUserPreferences(userId);
    const { meals } = await this.getMeals(userId, { limit: 10000 });
    const favorites = await this.getFavoriteMeals(userId);

    return {
      exportedAt: new Date().toISOString(),
      profile,
      preferences,
      meals,
      favorites,
    };
  }

  async deleteUserAccount(userId: string): Promise<boolean> {
    if (isSupabaseConfigured()) {
      try {
        await getSupabase().from('profiles').delete().eq('id', userId);
      } catch (err) {
        logger.warn('Supabase deleteUserAccount error', { err });
      }
    }

    const profile = memStore.profiles.get(userId);
    if (profile) {
      memStore.profilesByClerkId.delete(profile.clerkUserId);
      memStore.profiles.delete(userId);
    }
    memStore.preferences.delete(userId);

    // Delete meals
    for (const [id, m] of memStore.meals.entries()) {
      if (m.userId === userId) memStore.meals.delete(id);
    }
    // Delete favorites
    for (const [id, f] of memStore.favoriteMeals.entries()) {
      if (f.userId === userId) memStore.favoriteMeals.delete(id);
    }
    // Delete hydration
    memStore.hydrationLogs = memStore.hydrationLogs.filter((h) => h.userId !== userId);

    return true;
  }

  private async incrementTotalScans(userId: string): Promise<void> {
    const profile = await this.getProfileById(userId);
    if (profile) {
      await this.updateProfile(userId, {
        totalScans: (profile.totalScans || 0) + 1,
      });
    }
  }

  private mapSupabaseProfile(row: any): UserProfile {
    return {
      id: row.id,
      clerkUserId: row.clerk_user_id,
      email: row.email,
      name: row.name,
      profileImageUrl: row.profile_image_url,
      age: row.age,
      gender: row.gender,
      heightCm: row.height_cm ? Number(row.height_cm) : null,
      weightKg: row.weight_kg ? Number(row.weight_kg) : null,
      activityLevel: row.activity_level,
      goal: row.goal,
      targetCalories: Number(row.target_calories || 2000),
      targetProtein: Number(row.target_protein || 100),
      targetCarbs: Number(row.target_carbs || 250),
      targetFat: Number(row.target_fat || 65),
      targetWaterMl: Number(row.target_water_ml || 2500),
      streakDays: row.streak_days || 0,
      totalScans: row.total_scans || 0,
      dietaryRestrictions: Array.isArray(row.dietary_restrictions) ? row.dietary_restrictions : [],
      allergies: Array.isArray(row.allergies) ? row.allergies : [],
      healthConditions: Array.isArray(row.health_conditions) ? row.health_conditions : [],
      medications: Array.isArray(row.medications) ? row.medications : [],
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }

  private mapSupabaseMeal(row: any): MealRecord {
    return {
      id: row.id,
      userId: row.user_id,
      name: row.name,
      mealType: row.meal_type,
      imageUrl: row.image_url,
      storagePath: row.storage_path,
      loggedAt: row.logged_at,
      calories: Number(row.calories || 0),
      protein: Number(row.protein || 0),
      carbs: Number(row.carbs || 0),
      fat: Number(row.fat || 0),
      fiber: Number(row.fiber || 0),
      sugar: Number(row.sugar || 0),
      sodium: Number(row.sodium || 0),
      healthScore: row.health_score,
      recommendations: row.recommendations,
      novaGroup: row.nova_group || 1,
      barcode: row.barcode,
      isFavorite: !!row.is_favorite,
      itemCount: row.item_count || 1,
      unitName: row.unit_name || 'serving',
      servingSize: row.serving_size || '1 serving',
      unitWeightGrams: Number(row.unit_weight_grams || 100),
      ingredients: Array.isArray(row.ingredients) ? row.ingredients : [],
      additives: (Array.isArray(row.additives) ? row.additives : []) as FoodAdditive[],
      allergens: Array.isArray(row.allergens) ? row.allergens : [],
      vitaminsMinerals: (Array.isArray(row.vitamins_minerals) ? row.vitamins_minerals : []) as VitaminMineral[],
      isAiEstimate: row.is_ai_estimate !== undefined ? !!row.is_ai_estimate : true,
      userEdited: !!row.user_edited,
      rawNutritionInfo: row.raw_nutrition_info,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}

export const db = new DatabaseService();
