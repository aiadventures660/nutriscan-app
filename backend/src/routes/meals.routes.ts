import { Router } from 'express';
import { mealsController } from '../controllers/meals.controller.js';
import { requireAuth } from '../middleware/auth.middleware.js';

const router = Router();

router.use(requireAuth);

router.get('/', (req, res, next) => mealsController.getMeals(req, res).catch(next));
router.get('/:id', (req, res, next) => mealsController.getMealById(req, res).catch(next));
router.post('/', (req, res, next) => mealsController.createMeal(req, res).catch(next));
router.put('/:id', (req, res, next) => mealsController.updateMeal(req, res).catch(next));
router.delete('/:id', (req, res, next) => mealsController.deleteMeal(req, res).catch(next));

export default router;
