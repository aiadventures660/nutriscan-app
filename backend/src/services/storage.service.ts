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
          // Generate short-lived signed URL for private user photo storage
          const { data: signedData, error: signedError } = await getSupabase().storage
            .from(env.SUPABASE_STORAGE_BUCKET)
            .createSignedUrl(filename, 3600); // 1-hour expiration

          if (!signedError && signedData?.signedUrl) {
            return {
              url: signedData.signedUrl,
              storagePath: filename,
            };
          }

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
          // Generate short-lived signed URL for private avatar storage
          const { data: signedData, error: signedError } = await getSupabase().storage
            .from(env.SUPABASE_AVATAR_BUCKET)
            .createSignedUrl(filename, 3600);

          if (!signedError && signedData?.signedUrl) {
            return {
              url: signedData.signedUrl,
              storagePath: filename,
            };
          }

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

  /**
   * Generate short-lived signed URL for a single storage path
   * Validates user ownership when expectedUserId is provided
   */
  async getSignedUrl(
    storagePath: string,
    expiresIn: number = 3600,
    expectedUserId?: string
  ): Promise<string | null> {
    if (!isSupabaseConfigured() || !storagePath || storagePath.startsWith('local:')) {
      return null;
    }
    // Defense-in-depth: Prevent cross-user storage path access
    if (expectedUserId && !storagePath.startsWith(`${expectedUserId}/`)) {
      logger.warn('Storage signed URL generation rejected: path does not match expected user', {
        storagePath,
        expectedUserId,
      });
      return null;
    }
    try {
      const { data, error } = await getSupabase().storage
        .from(env.SUPABASE_STORAGE_BUCKET)
        .createSignedUrl(storagePath, expiresIn);
      if (!error && data?.signedUrl) {
        return data.signedUrl;
      }
    } catch (err) {
      logger.warn('Failed to generate signed URL', { err, storagePath });
    }
    return null;
  }

  /**
   * Batch generate short-lived signed URLs for multiple storage paths
   * Validates user ownership when expectedUserId is provided
   */
  async getSignedUrls(
    storagePaths: string[],
    expiresIn: number = 3600,
    expectedUserId?: string
  ): Promise<Map<string, string>> {
    const map = new Map<string, string>();
    if (!isSupabaseConfigured() || storagePaths.length === 0) {
      return map;
    }
    try {
      const validPaths = Array.from(
        new Set(
          storagePaths.filter((p) => {
            if (!p || p.startsWith('local:')) return false;
            if (expectedUserId && !p.startsWith(`${expectedUserId}/`)) return false;
            return true;
          })
        )
      );
      if (validPaths.length === 0) return map;

      const { data, error } = await getSupabase().storage
        .from(env.SUPABASE_STORAGE_BUCKET)
        .createSignedUrls(validPaths, expiresIn);

      if (!error && Array.isArray(data)) {
        for (const item of data) {
          if (item.path && item.signedUrl) {
            map.set(item.path, item.signedUrl);
          }
        }
      }
    } catch (err) {
      logger.warn('Failed to batch generate signed URLs', { err });
    }
    return map;
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
