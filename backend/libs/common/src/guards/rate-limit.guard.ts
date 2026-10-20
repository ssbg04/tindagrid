import {
  Injectable,
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';

export const RATE_LIMIT_KEY = 'rate_limit';
export interface RateLimitOptions {
  limit: number;
  windowMs: number;
}

export const RateLimit = (limit: number, windowMs: number = 60000) =>
  SetMetadata(RATE_LIMIT_KEY, { limit, windowMs });

interface RateRecord {
  timestamps: number[];
}

@Injectable()
export class RateLimitGuard implements CanActivate {
  private readonly hits = new Map<string, RateRecord>();
  private readonly cleanupInterval: ReturnType<typeof setInterval>;

  constructor(private readonly reflector: Reflector) {
    // Purge stale hits every 2 minutes to conserve RAM (<150MB constraint)
    this.cleanupInterval = setInterval(() => {
      const now = Date.now();
      for (const [key, record] of this.hits.entries()) {
        record.timestamps = record.timestamps.filter((ts) => now - ts < 120000);
        if (record.timestamps.length === 0) {
          this.hits.delete(key);
        }
      }
    }, 120000);
    this.cleanupInterval.unref?.();
  }

  canActivate(context: ExecutionContext): boolean {
    const rateOptions = this.reflector.getAllAndOverride<RateLimitOptions | undefined>(
      RATE_LIMIT_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!rateOptions) {
      return true; // No rate limit on this route
    }

    const req = context.switchToHttp().getRequest();
    const res = context.switchToHttp().getResponse();
    const ip = req.ip || req.connection?.remoteAddress || 'unknown-ip';
    const route = req.path || '';
    const key = `${ip}:${route}`;
    const now = Date.now();

    let record = this.hits.get(key);
    if (!record) {
      record = { timestamps: [] };
      this.hits.set(key, record);
    }

    // Filter within window
    record.timestamps = record.timestamps.filter(
      (ts) => now - ts < rateOptions.windowMs,
    );

    if (record.timestamps.length >= rateOptions.limit) {
      res.header?.('Retry-After', Math.ceil(rateOptions.windowMs / 1000).toString());
      throw new HttpException(
        {
          statusCode: HttpStatus.TOO_MANY_REQUESTS,
          message: 'Too many requests. Please slow down.',
          retryAfterSeconds: Math.ceil(rateOptions.windowMs / 1000),
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    record.timestamps.push(now);
    res.header?.('X-RateLimit-Limit', rateOptions.limit.toString());
    res.header?.(
      'X-RateLimit-Remaining',
      (rateOptions.limit - record.timestamps.length).toString(),
    );

    return true;
  }
}
