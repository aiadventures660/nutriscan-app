import { Response, NextFunction } from 'express';
import { z } from 'zod';
import { db } from '../services/db.service.js';
import { storageService } from '../services/storage.service.js';
import { AuthenticatedRequest } from '../types/index.js';

const normalizeEnum = (val: unknown) => {
  if (typeof val === 'string') {
    return val.trim().toLowerCase().replace(/[\s-]+/g, '_');
  }
  return val;
};

const updateProfileSchema = z.object({
  name: z.string().optional(),
  age: z.number().int().min(10).max(120).optional(),
  gender: z.preprocess(normalizeEnum, z.enum(['male', 'female', 'other', 'prefer_not_to_say']).optional()),
  heightCm: z.number().min(40).max(280).optional(),
  weightKg: z.number().min(20).max(400).optional(),
  activityLevel: z.preprocess(normalizeEnum, z.enum(['sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extra_active']).optional()),
  goal: z.preprocess(normalizeEnum, z.enum(['healthy_lifestyle', 'lose_weight', 'build_muscle', 'keto_low_carb', 'maintain_weight']).optional()),
  targetCalories: z.number().min(500).max(10000).optional(),
  targetProtein: z.number().min(10).max(500).optional(),
  targetCarbs: z.number().min(10).max(1000).optional(),
  targetFat: z.number().min(5).max(500).optional(),
  targetWaterMl: z.number().min(500).max(10000).optional(),
  dietaryRestrictions: z.array(z.string()).optional(),
  allergies: z.array(z.string()).optional(),
  healthConditions: z.array(z.string()).optional(),
  medications: z.array(z.string()).optional(),
});

const updatePreferencesSchema = z.object({
  notificationsEnabled: z.boolean().optional(),
  dailyReminders: z.boolean().optional(),
  reminderTime: z.string().optional(),
  units: z.string().optional(),
  language: z.string().optional(),
  dataAnalytics: z.boolean().optional(),
  aiSuggestions: z.boolean().optional(),
  theme: z.string().optional(),
});

export class ProfileController {
  async getProfile(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const profile = await db.getProfileById(userId);
    if (!profile) {
      res.status(404).json({ success: false, error: 'Not Found', message: 'Profile not found' });
      return;
    }
    res.json({ success: true, data: profile });
  }

  async updateProfile(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const validated = updateProfileSchema.parse(req.body);
    const updated = await db.updateProfile(userId, validated);
    res.json({ success: true, data: updated, message: 'Profile updated successfully' });
  }

  async syncOnboardingProfile(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const validated = updateProfileSchema.parse(req.body);
    const updated = await db.updateProfile(userId, validated);
    res.json({ success: true, data: updated, message: 'Onboarding profile synced successfully' });
  }

  async uploadAvatar(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    if (!req.file) {
      res.status(400).json({ success: false, error: 'Bad Request', message: 'No image file uploaded' });
      return;
    }

    const { url, storagePath } = await storageService.uploadAvatar(
      userId,
      req.file.buffer,
      req.file.mimetype
    );

    const updated = await db.updateProfile(userId, { profileImageUrl: url });
    res.json({
      success: true,
      data: { profile: updated, avatarUrl: url, storagePath },
      message: 'Avatar uploaded successfully',
    });
  }

  async getPreferences(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const prefs = await db.getUserPreferences(userId);
    res.json({ success: true, data: prefs });
  }

  async updatePreferences(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const validated = updatePreferencesSchema.parse(req.body);
    const updated = await db.updateUserPreferences(userId, validated);
    res.json({ success: true, data: updated, message: 'Preferences updated successfully' });
  }
}

export const profileController = new ProfileController();
