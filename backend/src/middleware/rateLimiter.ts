import rateLimit from 'express-rate-limit';
import { env } from '../config/env.js';

export const generalRateLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.RATE_LIMIT_MAX_REQUESTS,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: 'Too Many Requests',
    message: 'Too many requests from this IP address. Please try again after 15 minutes.',
  },
});

export const aiRateLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.AI_RATE_LIMIT_MAX_REQUESTS,
  keyGenerator: (req: any) => req.user?.id || req.ip || 'anonymous',
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: 'Too Many Requests',
    message: 'AI Vision analysis rate limit exceeded. Please wait a few minutes before scanning again.',
  },
});
