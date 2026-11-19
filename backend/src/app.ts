import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import path from 'path';

import { env } from './config/env.js';
import { generalRateLimiter } from './middleware/rateLimiter.js';
import { errorHandler, notFoundHandler } from './middleware/error.middleware.js';

import profileRoutes from './routes/profile.routes.js';
import aiRoutes from './routes/ai.routes.js';
import mealsRoutes from './routes/meals.routes.js';
import dashboardRoutes from './routes/dashboard.routes.js';
import userRoutes from './routes/user.routes.js';

export function createApp(): Application {
  const app = express();

  // Security Headers
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    })
  );

  // CORS Configuration
  app.use(
    cors({
      origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(','),
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    })
  );

  // Request Logging
  if (env.NODE_ENV !== 'test') {
    app.use(morgan('dev'));
  }

  // Body Parsing
  app.use(express.json({ limit: '15mb' }));
  app.use(express.urlencoded({ extended: true, limit: '15mb' }));

  // Static files for local uploads fallback
  const uploadsDir = path.resolve(process.cwd(), 'uploads');
  app.use('/uploads', express.static(uploadsDir));

  // Rate Limiting on API endpoints
  app.use('/api', generalRateLimiter);

  // Health Check Endpoint (Render & monitoring)
  app.get('/health', (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'nutriscan-backend',
      version: '1.0.0',
      uptime: process.uptime(),
      environment: env.NODE_ENV,
    });
  });

  // API v1 Routes
  app.use('/api/v1/profile', profileRoutes);
  app.use('/api/v1/ai', aiRoutes);
  app.use('/api/v1/meals', mealsRoutes);
  app.use('/api/v1/dashboard', dashboardRoutes);
  app.use('/api/v1/user', userRoutes);

  // Root welcome
  app.get('/', (_req: Request, res: Response) => {
    res.json({
      name: 'NutriScan Pro API',
      version: '1.0.0',
      description: 'Production backend for NutriScan AI Nutrition Platform',
      healthCheck: '/health',
      docs: '/api/v1',
    });
  });

  // 404 & Error Handling
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
