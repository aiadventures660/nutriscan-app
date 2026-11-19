import { Router } from 'express';
import { userController } from '../controllers/user.controller.js';
import { requireAuth } from '../middleware/auth.middleware.js';

const router = Router();

router.use(requireAuth);

router.get('/export', (req, res) => userController.exportData(req, res));
router.delete('/account', (req, res) => userController.deleteAccount(req, res));
router.get('/favorites', (req, res) => userController.getFavorites(req, res));
router.post('/favorites', (req, res) => userController.addFavorite(req, res));
router.delete('/favorites/:id', (req, res) => userController.removeFavorite(req, res));

export default router;
