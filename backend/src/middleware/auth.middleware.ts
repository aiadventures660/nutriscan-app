import { Response, NextFunction } from 'express';
import { clerkClient, verifyClerkSessionToken } from '../config/clerk.js';
import { db } from '../services/db.service.js';
import { AuthenticatedRequest } from '../types/index.js';
import { logger } from '../utils/logger.js';

export async function requireAuth(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        success: false,
        error: 'Unauthorized',
        message: 'Missing or malformed Authorization header with Bearer token.',
      });
      return;
    }

    const token = authHeader.substring(7).trim();
    if (!token) {
      res.status(401).json({
        success: false,
        error: 'Unauthorized',
        message: 'Empty Bearer token provided.',
      });
      return;
    }

    // Verify token with Clerk
    let decodedToken;
    try {
      decodedToken = await verifyClerkSessionToken(token);
    } catch (verifyError: any) {
      logger.warn('Clerk session token verification failed', { error: verifyError?.message });
      res.status(401).json({
        success: false,
        error: 'Unauthorized',
        message: 'Invalid or expired session token.',
      });
      return;
    }

    const clerkUserId = decodedToken.sub;
    if (!clerkUserId) {
      res.status(401).json({
        success: false,
        error: 'Unauthorized',
        message: 'Token does not contain a valid user identifier.',
      });
      return;
    }

    // Lookup user in database
    let profile = await db.getProfileByClerkId(clerkUserId);

    // Auto-bootstrap profile if not yet in database
    if (!profile) {
      logger.info(`Bootstrapping new database profile for Clerk user: ${clerkUserId}`);
      let email = decodedToken.email as string | undefined;
      let name: string | undefined;
      let profileImageUrl: string | undefined;

      try {
        const clerkUser = await clerkClient.users.getUser(clerkUserId);
        if (clerkUser) {
          email = clerkUser.emailAddresses?.[0]?.emailAddress || email;
          const firstName = clerkUser.firstName || '';
          const lastName = clerkUser.lastName || '';
          name = `${firstName} ${lastName}`.trim() || undefined;
          profileImageUrl = clerkUser.imageUrl || undefined;
        }
      } catch (clerkErr) {
        logger.warn('Could not fetch Clerk user details during bootstrap', { clerkErr });
      }

      profile = await db.createProfile({
        clerkUserId,
        email: email || `${clerkUserId}@user.nutriscan.app`,
        name,
        profileImageUrl,
      });
    }

    // Attach verified user to request
    req.user = {
      id: profile.id,
      clerkUserId: profile.clerkUserId,
      email: profile.email,
      name: profile.name || undefined,
    };

    next();
  } catch (error: any) {
    logger.error('Authentication middleware unhandled error', { error: error?.message });
    res.status(500).json({
      success: false,
      error: 'Internal Server Error',
      message: 'Failed to authenticate request.',
    });
  }
}
