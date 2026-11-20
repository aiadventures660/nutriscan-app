import { Response } from 'express';
import { z } from 'zod';
import { aiService } from '../services/ai.service.js';
import { storageService } from '../services/storage.service.js';
import { AuthenticatedRequest } from '../types/index.js';

const analyzeTextSchema = z.object({
  query: z
    .string()
    .trim()
    .min(1, 'Query or meal description is required')
    .max(500, 'Query exceeds maximum limit of 500 characters'),
});

function isValidImageFile(buffer: Buffer): boolean {
  if (!buffer || buffer.length < 12) return false;
  // JPEG: FF D8 FF
  if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return true;
  // PNG: 89 50 4E 47
  if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) return true;
  // GIF: GIF87a or GIF89a
  if (buffer[0] === 0x47 && buffer[1] === 0x49 && buffer[2] === 0x46) return true;
  // WEBP: RIFF....WEBP
  if (
    buffer[0] === 0x52 &&
    buffer[1] === 0x49 &&
    buffer[2] === 0x46 &&
    buffer[3] === 0x46 &&
    buffer[8] === 0x57 &&
    buffer[9] === 0x45 &&
    buffer[10] === 0x42 &&
    buffer[11] === 0x50
  )
    return true;
  // HEIF / HEIC: bytes 4-8 are 'ftyp'
  if (buffer.subarray(4, 8).toString('ascii') === 'ftyp') return true;

  return false;
}

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

    // Defense-in-depth: Validate magic bytes to prevent masqueraded executable/HTML uploads
    if (!isValidImageFile(req.file.buffer)) {
      res.status(400).json({
        success: false,
        error: 'Bad Request',
        message: 'Invalid file content. Uploaded file is not a supported image format.',
      });
      return;
    }

    const rawHint = req.body.hint || req.body.foodHint;
    const foodHint = typeof rawHint === 'string' ? rawHint.trim().slice(0, 200) : undefined;

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
