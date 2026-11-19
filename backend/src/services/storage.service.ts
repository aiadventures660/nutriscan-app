import fs from 'fs';
import path from 'path';
import { randomUUID } from 'crypto';
import { getSupabase, isSupabaseConfigured } from '../config/supabase.js';
import { env } from '../config/env.js';
import { logger } from '../utils/logger.js';

const LOCAL_UPLOADS_DIR = path.resolve(process.cwd(), 'uploads');
if (!fs.existsSync(LOCAL_UPLOADS_DIR)) {
  fs.mkdirSync(LOCAL_UPLOADS_DIR, { recursive: true });
}

export class StorageService {
  /**
   * Upload food image (for scan analysis and meal logging)
   */
  async uploadFoodImage(
    userId: string,
    buffer: Buffer,
    mimeType: string,
    originalName?: string
  ): Promise<{ url: string; storagePath: string }> {
    const ext = this.getExtensionFromMime(mimeType) || 'jpg';
    const filename = `${userId}/${Date.now()}_${randomUUID()}.${ext}`;

    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase().storage
          .from(env.SUPABASE_STORAGE_BUCKET)
          .upload(filename, buffer, {
            contentType: mimeType,
            upsert: true,
          });

        if (!error && data) {
          const { data: publicUrlData } = getSupabase().storage
            .from(env.SUPABASE_STORAGE_BUCKET)
            .getPublicUrl(filename);

          return {
            url: publicUrlData.publicUrl,
            storagePath: filename,
          };
        }
        logger.warn('Supabase storage upload failed, saving locally', { error });
      } catch (err) {
        logger.warn('Supabase storage exception, saving locally', { err });
      }
    }

    // Local file storage fallback
    const userDir = path.join(LOCAL_UPLOADS_DIR, userId);
    if (!fs.existsSync(userDir)) {
      fs.mkdirSync(userDir, { recursive: true });
    }
    const localFileName = `${Date.now()}_${randomUUID()}.${ext}`;
    const localFilePath = path.join(userDir, localFileName);
    fs.writeFileSync(localFilePath, buffer);

    const relativeUrl = `/uploads/${userId}/${localFileName}`;
    return {
      url: relativeUrl,
      storagePath: `local:${userId}/${localFileName}`,
    };
  }

  /**
   * Upload avatar image
   */
  async uploadAvatar(
    userId: string,
    buffer: Buffer,
    mimeType: string
  ): Promise<{ url: string; storagePath: string }> {
    const ext = this.getExtensionFromMime(mimeType) || 'jpg';
    const filename = `${userId}/avatar_${Date.now()}.${ext}`;

    if (isSupabaseConfigured()) {
      try {
        const { data, error } = await getSupabase().storage
          .from(env.SUPABASE_AVATAR_BUCKET)
          .upload(filename, buffer, {
            contentType: mimeType,
            upsert: true,
          });

        if (!error && data) {
          const { data: publicUrlData } = getSupabase().storage
            .from(env.SUPABASE_AVATAR_BUCKET)
            .getPublicUrl(filename);

          return {
            url: publicUrlData.publicUrl,
            storagePath: filename,
          };
        }
      } catch (err) {
        logger.warn('Supabase avatar upload failed, saving locally', { err });
      }
    }

    const userDir = path.join(LOCAL_UPLOADS_DIR, userId);
    if (!fs.existsSync(userDir)) {
      fs.mkdirSync(userDir, { recursive: true });
    }
    const localFileName = `avatar_${Date.now()}.${ext}`;
    const localFilePath = path.join(userDir, localFileName);
    fs.writeFileSync(localFilePath, buffer);

    return {
      url: `/uploads/${userId}/${localFileName}`,
      storagePath: `local:${userId}/${localFileName}`,
    };
  }

  private getExtensionFromMime(mimeType: string): string {
    const map: Record<string, string> = {
      'image/jpeg': 'jpg',
      'image/jpg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp',
      'image/gif': 'gif',
    };
    return map[mimeType.toLowerCase()] || 'jpg';
  }
}

export const storageService = new StorageService();
