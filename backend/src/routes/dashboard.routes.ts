import { Router } from 'express';
import { dashboardController } from '../controllers/dashboard.controller.js';
import { requireAuth } from '../middleware/auth.middleware.js';

const router = Router();

router.use(requireAuth);

router.get('/daily', (req, res, next) => dashboardController.getDailySummary(req, res).catch(next));
router.get('/weekly', (req, res, next) => dashboardController.getWeeklySummary(req, res).catch(next));
router.post('/hydration', (req, res, next) => dashboardController.logHydration(req, res).catch(next));

export default router;
