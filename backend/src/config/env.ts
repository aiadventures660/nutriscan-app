import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  PORT: z.string().default('4000').transform((val) => parseInt(val, 10)),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  
  // Clerk Authentication
  CLERK_PUBLISHABLE_KEY: z.string().min(1, 'CLERK_PUBLISHABLE_KEY is required'),
  CLERK_SECRET_KEY: z.string().min(1, 'CLERK_SECRET_KEY is required'),
  
  // Supabase
  SUPABASE_URL: z.string().url('SUPABASE_URL must be a valid URL').default('https://uqzmlmxqrvxkdsasakmn.supabase.co'),
  SUPABASE_SERVICE_ROLE_KEY: z
    .string()
    .default(
      (process.env.SUPABASE_SERVICE_ROLE_KEY &&
        process.env.SUPABASE_SERVICE_ROLE_KEY !== 'placeholder_service_role_key')
        ? process.env.SUPABASE_SERVICE_ROLE_KEY
        : (process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || 'placeholder_service_role_key')
    ),
  SUPABASE_STORAGE_BUCKET: z.string().default('food-images'),
  SUPABASE_AVATAR_BUCKET: z.string().default('user-avatars'),

  // Google Gemini AI
  GEMINI_API_KEY: z.string().default(''),
  GEMINI_MODEL: z.string().default('gemini-3.6-flash'),
  
  // Security
  CORS_ORIGIN: z.string().default('*'),
  RATE_LIMIT_WINDOW_MS: z.string().default('900000').transform((val) => parseInt(val, 10)),
  RATE_LIMIT_MAX_REQUESTS: z.string().default('200').transform((val) => parseInt(val, 10)),
  AI_RATE_LIMIT_MAX_REQUESTS: z.string().default('50').transform((val) => parseInt(val, 10)),
});

export const env = envSchema.parse(process.env);
