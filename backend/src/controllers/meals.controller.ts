import { Response } from 'express';
import { z } from 'zod';
import { db } from '../services/db.service.js';
import { AuthenticatedRequest } from '../types/index.js';

const normalizeMealType = (val: unknown) => {
  if (typeof val === 'string') {
    const s = val.trim().toLowerCase();
    if (s.startsWith('breakfast')) return 'Breakfast';
    if (s.startsWith('lunch')) return 'Lunch';
    if (s.startsWith('dinner')) return 'Dinner';
    if (s.startsWith('snack')) return 'Snack';
  }
  return val;
};

const createMealSchema = z.object({
  name: z.string().min(1, 'Meal name is required'),
  mealType: z.preprocess(normalizeMealType, z.enum(['Breakfast', 'Lunch', 'Dinner', 'Snack'])).default('Lunch'),
  imageUrl: z.string().optional().nullable(),
  storagePath: z.string().optional().nullable(),
  loggedAt: z.string().optional(),
  calories: z.number().min(0),
  protein: z.number().min(0),
  carbs: z.number().min(0),
  fat: z.number().min(0),
  fiber: z.number().min(0).optional(),
  sugar: z.number().min(0).optional(),
  sodium: z.number().min(0).optional(),
  healthScore: z.string().optional(),
  recommendations: z.string().optional(),
  novaGroup: z.number().int().min(1).max(4).optional(),
  barcode: z.string().optional().nullable(),
  isFavorite: z.boolean().optional(),
  itemCount: z.number().min(1).optional(),
  unitName: z.string().optional(),
  servingSize: z.string().optional(),
  unitWeightGrams: z.number().optional(),
  ingredients: z.array(z.string()).optional(),
  additives: z.array(z.any()).optional(),
  allergens: z.array(z.string()).optional(),
  vitaminsMinerals: z.array(z.any()).optional(),
  isAiEstimate: z.boolean().optional(),
  userEdited: z.boolean().optional(),
  rawNutritionInfo: z.string().optional().nullable(),
});

const updateMealSchema = createMealSchema.partial();

export class MealsController {
  async getMeals(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 20;
    const mealType = req.query.mealType as string | undefined;
    const search = req.query.search as string | undefined;
    const startDate = req.query.startDate as string | undefined;
    const endDate = req.query.endDate as string | undefined;

    const result = await db.getMeals(userId, {
      page,
      limit,
      mealType,
      search,
      startDate,
      endDate,
    });

    res.json({
      success: true,
      data: result.meals,
      pagination: {
        total: result.total,
        page: result.page,
        limit: result.limit,
        totalPages: Math.ceil(result.total / result.limit),
      },
    });
  }

  async getMealById(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const mealId = String(req.params.id);

    const meal = await db.getMealById(userId, mealId);
    if (!meal) {
      res.status(404).json({ success: false, error: 'Not Found', message: 'Meal entry not found' });
      return;
    }

    res.json({ success: true, data: meal });
  }

  async createMeal(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const validated = createMealSchema.parse(req.body);

    const meal = await db.createMeal(userId, validated);
    res.status(201).json({
      success: true,
      data: meal,
      message: 'Meal logged successfully',
    });
  }

  async updateMeal(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const mealId = String(req.params.id);
    const validated = updateMealSchema.parse(req.body);

    const updated = await db.updateMeal(userId, mealId, validated);
    res.json({
      success: true,
      data: updated,
      message: 'Meal updated successfully',
    });
  }

  async deleteMeal(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const mealId = String(req.params.id);

    const deleted = await db.deleteMeal(userId, mealId);
    if (!deleted) {
      res.status(404).json({ success: false, error: 'Not Found', message: 'Meal not found or already deleted' });
      return;
    }

    res.json({
      success: true,
      message: 'Meal deleted successfully',
    });
  }
}

export const mealsController = new MealsController();
