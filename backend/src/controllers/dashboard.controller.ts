import { Response } from 'express';
import { z } from 'zod';
import { db } from '../services/db.service.js';
import { AuthenticatedRequest } from '../types/index.js';

const logHydrationSchema = z.object({
  amountMl: z.number().int().min(1).max(5000),
});

export class DashboardController {
  async getDailySummary(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const dateStr = (req.query.date as string) || new Date().toISOString().split('T')[0];

    const summary = await db.getDailySummary(userId, dateStr);
    res.json({
      success: true,
      data: summary,
    });
  }

  async getWeeklySummary(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const endDateStr = (req.query.endDate as string) || new Date().toISOString().split('T')[0];

    const weekly = await db.getWeeklySummary(userId, endDateStr);
    res.json({
      success: true,
      data: weekly,
    });
  }

  async logHydration(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    const validated = logHydrationSchema.parse(req.body);

    const log = await db.logHydration(userId, validated.amountMl);
    const todayStr = new Date().toISOString().split('T')[0];
    const totalWaterMl = await db.getHydrationForDate(userId, todayStr);

    res.json({
      success: true,
      data: {
        log,
        totalWaterMl,
      },
      message: `${validated.amountMl}ml logged successfully`,
    });
  }
}

export const dashboardController = new DashboardController();
