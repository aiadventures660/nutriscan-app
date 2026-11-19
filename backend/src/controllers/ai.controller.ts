import { Response } from 'express';
import { z } from 'zod';
import { aiService } from '../services/ai.service.js';
import { storageService } from '../services/storage.service.js';
import { AuthenticatedRequest } from '../types/index.js';

const analyzeTextSchema = z.object({
  query: z.string().min(1, 'Query or meal description is required'),
});

export class AIController {
  async analyzeImage(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user!.id;
    if (!req.file) {
      res.status(400).json({
        success: false,
        error: 'Bad Request',
        message: 'Food image file is required for visual analysis.',
      });
      return;
    }

    const foodHint = req.body.hint || req.body.foodHint;

    // 1. Upload image securely to Supabase Storage or local secure folder
    const uploadResult = await storageService.uploadFoodImage(
      userId,
      req.file.buffer,
      req.file.mimetype,
      req.file.originalname
    );

    // 2. Perform AI Vision nutritional estimation
    const analysis = await aiService.analyzeFoodImage(
      req.file.buffer,
      req.file.mimetype,
      foodHint
    );

    // Attach uploaded image URL to the result
    analysis.imageUrl = uploadResult.url;

    res.json({
      success: true,
      data: {
        ...analysis,
        imageUrl: uploadResult.url,
        storagePath: uploadResult.storagePath,
      },
      message: 'Food image analyzed successfully. Values are AI-generated estimates.',
    });
  }

  async analyzeText(req: AuthenticatedRequest, res: Response): Promise<void> {
    const validated = analyzeTextSchema.parse(req.body);
    const analysis = await aiService.analyzeFoodText(validated.query);

    res.json({
      success: true,
      data: analysis,
      message: 'Nutritional estimates retrieved successfully.',
    });
  }
}

export const aiController = new AIController();
