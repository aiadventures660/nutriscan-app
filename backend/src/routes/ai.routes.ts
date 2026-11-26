import { Router } from 'express';
import { aiController } from '../controllers/ai.controller.js';
import { requireAuth } from '../middleware/auth.middleware.js';
import { uploadSingleImage } from '../middleware/upload.middleware.js';
import { aiRateLimiter } from '../middleware/rateLimiter.js';

const router = Router();

router.use(requireAuth);
router.use(aiRateLimiter);

router.post('/analyze-image', uploadSingleImage.single('image'), (req, res) =>
  aiController.analyzeImage(req, res)
);

router.post('/analyze-text', (req, res) =>
  aiController.analyzeText(req, res)
);

router.post('/meal-plan', (req, res, next) =>
  aiController.generateMealPlan(req, res).catch(next)
);

export default router;
