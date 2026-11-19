import { createApp } from './app.js';
import { env } from './config/env.js';
import { logger } from './utils/logger.js';

const app = createApp();

const server = app.listen(env.PORT, '0.0.0.0', () => {
  logger.info(`NutriScan Backend running on 0.0.0.0:${env.PORT} in ${env.NODE_ENV} mode`);
  logger.info(`Health check available at: http://localhost:${env.PORT}/health`);
  logger.info(`Android Emulator endpoint: http://10.0.2.2:${env.PORT}/api/v1`);
});

const gracefulShutdown = (signal: string) => {
  logger.info(`Received ${signal}. Gracefully shutting down...`);
  server.close(() => {
    logger.info('HTTP server closed.');
    process.exit(0);
  });

  setTimeout(() => {
    logger.error('Forcefully terminating process after timeout.');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
