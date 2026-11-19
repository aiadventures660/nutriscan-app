import { Router } from 'express';
import { profileController } from '../controllers/profile.controller.js';
import { requireAuth } from '../middleware/auth.middleware.js';
import { uploadSingleImage } from '../middleware/upload.middleware.js';

const router = Router();

router.use(requireAuth);

router.get('/', (req, res, next) => profileController.getProfile(req, res).catch(next));
router.put('/', (req, res, next) => profileController.updateProfile(req, res).catch(next));
router.post('/sync', (req, res, next) => profileController.syncOnboardingProfile(req, res).catch(next));
router.post('/avatar', uploadSingleImage.single('avatar'), (req, res, next) =>
  profileController.uploadAvatar(req, res).catch(next)
);
router.get('/preferences', (req, res, next) => profileController.getPreferences(req, res).catch(next));
router.put('/preferences', (req, res, next) => profileController.updatePreferences(req, res).catch(next));

export default router;
