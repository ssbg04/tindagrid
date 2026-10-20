import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class SyncAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException(
        'Kailangan ng valid session token para mag-sync sa Neon cloud.',
      );
    }

    const token = authHeader.split(' ')[1];
    try {
      const payload = await this.jwtService.verifyAsync(token, {
        secret:
          process.env.JWT_SECRET ||
          'tindagrid_super_secret_jwt_key_change_in_production',
      });
      request.merchant = payload;
      return true;
    } catch {
      throw new UnauthorizedException(
        'Expired o imbalidong session token. Paki-login muli sa Tindahan PIN.',
      );
    }
  }
}
