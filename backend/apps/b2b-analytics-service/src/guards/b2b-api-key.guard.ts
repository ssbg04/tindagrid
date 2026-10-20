import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
  ForbiddenException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { DatabaseService } from '@lib/database';

@Injectable()
export class B2bApiKeyGuard implements CanActivate {
  constructor(private readonly db: DatabaseService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const apiKey =
      req.headers['x-api-key'] ||
      req.headers['X-API-Key'] ||
      req.query?.api_key;

    if (!apiKey || typeof apiKey !== 'string') {
      throw new UnauthorizedException(
        'Missing or invalid X-API-Key header. Access to B2B FMCG data feeds requires an authorized key.',
      );
    }

    const hashedKey = crypto
      .createHash('sha256')
      .update(apiKey.trim())
      .digest('hex');

    const keyRecord = await this.db.b2bApiKey.findUnique({
      where: { apiKeyHash: hashedKey },
    });

    if (!keyRecord) {
      throw new UnauthorizedException('Invalid B2B API Key provided.');
    }

    if (!keyRecord.isActive) {
      throw new ForbiddenException(
        'This B2B API Key has been suspended or deactivated.',
      );
    }

    req.b2bClient = {
      id: keyRecord.id,
      clientName: keyRecord.clientName,
      tier: keyRecord.tier,
      rateLimit: keyRecord.rateLimit,
    };

    return true;
  }
}
