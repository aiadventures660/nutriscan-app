import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { env } from './env.js';
import { logger } from '../utils/logger.js';

let supabaseClient: SupabaseClient | null = null;

export const isSupabaseConfigured = (): boolean => {
  return (
    env.SUPABASE_SERVICE_ROLE_KEY !== 'placeholder_service_role_key' &&
    env.SUPABASE_URL.startsWith('http') &&
    !env.SUPABASE_URL.includes('placeholder')
  );
};

export const getSupabase = (): SupabaseClient => {
  if (!supabaseClient) {
    if (!isSupabaseConfigured()) {
      logger.warn(
        'Supabase credentials not configured or using placeholders. Database service will use in-memory store for local testing.'
      );
    }
    supabaseClient = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });
  }
  return supabaseClient;
};
