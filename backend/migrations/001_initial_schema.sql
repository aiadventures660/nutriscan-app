-- NutriScan Pro Supabase PostgreSQL Schema
-- Migration: 001_initial_schema.sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. PROFILES TABLE
-- Securely maps verified Clerk user ID to user profile and nutrition targets
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    name TEXT,
    profile_image_url TEXT,
    age INT CHECK (age IS NULL OR (age >= 10 AND age <= 120)),
    gender TEXT CHECK (gender IS NULL OR gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
    height_cm NUMERIC(5, 2) CHECK (height_cm IS NULL OR (height_cm > 40 AND height_cm < 280)),
    weight_kg NUMERIC(5, 2) CHECK (weight_kg IS NULL OR (weight_kg > 20 AND weight_kg < 400)),
    activity_level TEXT CHECK (activity_level IS NULL OR activity_level IN ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extra_active')),
    goal TEXT CHECK (goal IS NULL OR goal IN ('healthy_lifestyle', 'lose_weight', 'build_muscle', 'keto_low_carb', 'maintain_weight')),
    target_calories NUMERIC(7, 2) DEFAULT 2000.0,
    target_protein NUMERIC(6, 2) DEFAULT 100.0,
    target_carbs NUMERIC(6, 2) DEFAULT 250.0,
    target_fat NUMERIC(6, 2) DEFAULT 65.0,
    target_water_ml INT DEFAULT 2500,
    streak_days INT DEFAULT 0,
    total_scans INT DEFAULT 0,
    dietary_restrictions JSONB DEFAULT '[]'::jsonb,
    allergies JSONB DEFAULT '[]'::jsonb,
    health_conditions JSONB DEFAULT '[]'::jsonb,
    medications JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookup by Clerk user ID
CREATE INDEX IF NOT EXISTS idx_profiles_clerk_user_id ON public.profiles(clerk_user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- ============================================================================
-- 2. USER PREFERENCES TABLE
-- User configuration, units, theme, notifications
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
    notifications_enabled BOOLEAN DEFAULT TRUE,
    daily_reminders BOOLEAN DEFAULT TRUE,
    reminder_time TEXT DEFAULT '08:00',
    units TEXT DEFAULT 'metric',
    language TEXT DEFAULT 'en',
    data_analytics BOOLEAN DEFAULT TRUE,
    ai_suggestions BOOLEAN DEFAULT TRUE,
    theme TEXT DEFAULT 'system',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);

-- ============================================================================
-- 3. MEALS TABLE
-- Logged meals, AI estimates, and user-edited nutritional values
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    meal_type TEXT CHECK (meal_type IN ('Breakfast', 'Lunch', 'Dinner', 'Snack')) DEFAULT 'Lunch',
    image_url TEXT,
    storage_path TEXT,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    calories NUMERIC(7, 2) NOT NULL DEFAULT 0.0,
    protein NUMERIC(6, 2) NOT NULL DEFAULT 0.0,
    carbs NUMERIC(6, 2) NOT NULL DEFAULT 0.0,
    fat NUMERIC(6, 2) NOT NULL DEFAULT 0.0,
    fiber NUMERIC(6, 2) DEFAULT 0.0,
    sugar NUMERIC(6, 2) DEFAULT 0.0,
    sodium NUMERIC(7, 2) DEFAULT 0.0,
    health_score TEXT,
    recommendations TEXT,
    nova_group INT DEFAULT 1 CHECK (nova_group >= 1 AND nova_group <= 4),
    barcode TEXT,
    is_favorite BOOLEAN DEFAULT FALSE,
    item_count INT DEFAULT 1,
    unit_name TEXT DEFAULT 'serving',
    serving_size TEXT DEFAULT '1 serving',
    unit_weight_grams NUMERIC(7, 2) DEFAULT 100.0,
    ingredients JSONB DEFAULT '[]'::jsonb,
    additives JSONB DEFAULT '[]'::jsonb,
    allergens JSONB DEFAULT '[]'::jsonb,
    vitamins_minerals JSONB DEFAULT '[]'::jsonb,
    is_ai_estimate BOOLEAN DEFAULT TRUE,
    user_edited BOOLEAN DEFAULT FALSE,
    raw_nutrition_info TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meals_user_id_logged_at ON public.meals(user_id, logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_meals_meal_type ON public.meals(user_id, meal_type);
CREATE INDEX IF NOT EXISTS idx_meals_barcode ON public.meals(barcode) WHERE barcode IS NOT NULL;

-- ============================================================================
-- 4. HYDRATION LOGS TABLE
-- Tracks daily water intake logs
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.hydration_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount_ml INT NOT NULL CHECK (amount_ml > 0),
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hydration_logs_user_logged_at ON public.hydration_logs(user_id, logged_at DESC);

-- ============================================================================
-- 5. FAVORITE MEALS TABLE
-- Frequently eaten meals for one-tap logging
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.favorite_meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    subtitle TEXT,
    calories NUMERIC(7, 2) DEFAULT 0.0,
    protein NUMERIC(6, 2) DEFAULT 0.0,
    carbs NUMERIC(6, 2) DEFAULT 0.0,
    fat NUMERIC(6, 2) DEFAULT 0.0,
    meal_data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_favorite_meals_user_id ON public.favorite_meals(user_id);

-- ============================================================================
-- 6. HEALTHIER ALTERNATIVES CACHE TABLE
-- Caches AI-suggested healthier swaps for faster queries
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.food_alternatives (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_food_name TEXT NOT NULL,
    alternative_name TEXT NOT NULL,
    calories NUMERIC(7, 2),
    protein NUMERIC(6, 2),
    carbs NUMERIC(6, 2),
    fat NUMERIC(6, 2),
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_food_alternatives_original ON public.food_alternatives(LOWER(original_food_name));

-- ============================================================================
-- 7. AUTO-UPDATE TRIGGER FUNCTION
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON public.user_preferences;
CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON public.user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_meals_updated_at ON public.meals;
CREATE TRIGGER update_meals_updated_at
    BEFORE UPDATE ON public.meals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 8. ROW LEVEL SECURITY (RLS)
-- Protects data access using PostgreSQL RLS policies
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hydration_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorite_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_alternatives ENABLE ROW LEVEL SECURITY;

-- Note: The Express backend connects via the Supabase Service Role key,
-- bypassing RLS at the database engine level, but enforces strict user isolation
-- programmatically by verifying the Clerk session JWT on every request and scoping
-- all queries by verified public.profiles.id.
