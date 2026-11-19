import { Response } from 'express';
import { db } from '../services/db.service.js';
import { clerkClient } from '../config/clerk.js';
import { AuthenticatedRequest } from '../types/index.js';
import { logger } from '../utils/logger.js';

export class UserController {
  async exportData(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const exportBundle = await db.exportUserData(userId);

    res.setHeader('Content-Type', 'application/json');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="nutriscan_export_${Date.now()}.json"`
    );
    res.json({
      success: true,
      data: exportBundle,
    });
  }

  async deleteAccount(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const clerkUserId = req.user!.clerkUserId;

    // 1. Delete all user database records
    await db.deleteUserAccount(userId);

    // 2. Delete user from Clerk directory
    try {
      await clerkClient.users.deleteUser(clerkUserId);
    } catch (err: any) {
      logger.warn('Could not delete user from Clerk', { err: err?.message });
    }

    res.json({
      success: true,
      message: 'Account and associated nutrition data permanently deleted.',
    });
  }

  async getFavorites(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const favorites = await db.getFavoriteMeals(userId);
    res.json({
      success: true,
      data: favorites,
    });
  }

  async addFavorite(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const meal = req.body;
    if (!meal || !meal.name) {
      res.status(400).json({ success: false, error: 'Bad Request', message: 'Meal data is required' });
      return;
    }

    const fav = await db.addFavoriteMeal(userId, meal);
    res.status(201).json({
      success: true,
      data: fav,
      message: 'Meal added to favorites',
    });
  }

  async removeFavorite(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const favoriteId = String(req.params.id);

    const removed = await db.removeFavoriteMeal(userId, favoriteId);
    if (!removed) {
      res.status(404).json({ success: false, error: 'Not Found', message: 'Favorite not found' });
      return;
    }

    res.json({
      success: true,
      message: 'Favorite removed successfully',
    });
  }
}

export const userController = new UserController();
