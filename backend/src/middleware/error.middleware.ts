import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { MulterError } from 'multer';
import { logger } from '../utils/logger.js';

export function notFoundHandler(req: Request, res: Response): void {
  res.status(404).json({
    success: false,
    error: 'Not Found',
    message: `Cannot ${req.method} ${req.originalUrl}`,
  });
}

export function errorHandler(
  err: any,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  logger.error('Unhandled Application Error:', {
    message: err.message,
    stack: err.stack,
  });

  if (err instanceof ZodError) {
    res.status(400).json({
      success: false,
      error: 'Validation Error',
      message: 'One or more request parameters failed validation.',
      details: err.issues.map((i) => ({
        path: i.path.join('.'),
        message: i.message,
      })),
    });
    return;
  }

  if (err instanceof MulterError) {
    res.status(400).json({
      success: false,
      error: 'File Upload Error',
      message: err.message,
      code: err.code,
    });
    return;
  }

  const statusCode = err.status || err.statusCode || 500;
  const isProduction = process.env.NODE_ENV === 'production';
  res.status(statusCode).json({
    success: false,
    error: err.name || 'Internal Server Error',
    message:
      statusCode >= 500 && isProduction
        ? 'An unexpected error occurred processing your request.'
        : err.message || 'An unexpected error occurred processing your request.',
  });
}
