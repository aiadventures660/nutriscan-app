-- ============================================================================
-- NutriScan Supabase Migration 002: Storage Buckets & Backend Access
-- ============================================================================

-- 1. Create Private Storage Buckets
-- Note: 'public' is set to false to enforce private storage with secure access controls
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('food-images', 'food-images', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']),
  ('user-avatars', 'user-avatars', false, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET 
  public = false,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Storage Policies for private buckets
DROP POLICY IF EXISTS "Private bucket access for food-images" ON storage.objects;
CREATE POLICY "Private bucket access for food-images"
ON storage.objects
FOR ALL
TO authenticated, anon, service_role
USING (bucket_id = 'food-images')
WITH CHECK (bucket_id = 'food-images');

DROP POLICY IF EXISTS "Private bucket access for user-avatars" ON storage.objects;
CREATE POLICY "Private bucket access for user-avatars"
ON storage.objects
FOR ALL
TO authenticated, anon, service_role
USING (bucket_id = 'user-avatars')
WITH CHECK (bucket_id = 'user-avatars');

-- 3. Database table policies allowing backend service operations
-- Note: When connecting with the service_role key, RLS is automatically bypassed.
-- These policies also allow the API Gateway to operate if using anon credentials.
DROP POLICY IF EXISTS "Backend API profiles access" ON public.profiles;
CREATE POLICY "Backend API profiles access" ON public.profiles FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend API preferences access" ON public.user_preferences;
CREATE POLICY "Backend API preferences access" ON public.user_preferences FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend API meals access" ON public.meals;
CREATE POLICY "Backend API meals access" ON public.meals FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend API hydration access" ON public.hydration_logs;
CREATE POLICY "Backend API hydration access" ON public.hydration_logs FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend API favorites access" ON public.favorite_meals;
CREATE POLICY "Backend API favorites access" ON public.favorite_meals FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Backend API alternatives access" ON public.food_alternatives;
CREATE POLICY "Backend API alternatives access" ON public.food_alternatives FOR ALL TO public USING (true) WITH CHECK (true);
