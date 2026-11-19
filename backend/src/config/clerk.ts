import { createClerkClient, verifyToken } from '@clerk/backend';
import { env } from './env.js';
import { logger } from '../utils/logger.js';

export const clerkClient = createClerkClient({
  secretKey: env.CLERK_SECRET_KEY,
  publishableKey: env.CLERK_PUBLISHABLE_KEY,
});

export interface VerifiedClerkToken {
  sub: string; // Clerk User ID
  sid?: string; // Clerk Session ID
  email?: string;
  [key: string]: unknown;
}

export async function verifyClerkSessionToken(token: string): Promise<VerifiedClerkToken> {
  try {
    const payload = await verifyToken(token, {
      secretKey: env.CLERK_SECRET_KEY,
    });
    return payload as VerifiedClerkToken;
  } catch (error) {
    logger.warn('Failed to verify Clerk token via verifyToken', { error });
    throw error;
  }
}
