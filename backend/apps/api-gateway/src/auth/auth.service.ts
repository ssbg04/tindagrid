import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { DatabaseService } from '@lib/database';
import bcrypt from 'bcryptjs';
import { RegisterDto, LoginDto, RecoverPinDto } from './dto/auth.dto.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly db: DatabaseService,
    private readonly jwtService: JwtService,
  ) {}

  private normalizePhone(phone: string): string {
    const cleaned = phone.replace(/[\s-]/g, '');
    if (cleaned.startsWith('09')) {
      return '+63' + cleaned.substring(1);
    }
    return cleaned;
  }

  async register(dto: RegisterDto) {
    const normalizedPhone = this.normalizePhone(dto.phone);

    // Check if phone already registered
    const existing = await this.db.merchant.findUnique({
      where: { phone: normalizedPhone },
    });

    if (existing) {
      throw new ConflictException(
        'Ang numero ng teleponong ito ay nakarehistro na. Paki-login na lang gamit ang iyong Store PIN.',
      );
    }

    // Hash Store PIN
    const pinHash = await bcrypt.hash(dto.pin, 10);

    // Hash Security Answer if provided
    let securityAnswerHash: string | undefined;
    if (dto.securityAnswer) {
      const normalizedAnswer = dto.securityAnswer.trim().toLowerCase();
      securityAnswerHash = await bcrypt.hash(normalizedAnswer, 10);
    }

    // Generate unique slug for default store
    const storeName = dto.storeName || `${dto.fullName}'s Tindahan`;
    const baseSlug = storeName
      .toLowerCase()
      .replace(/[^a-z0-9]/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '');
    const randomSuffix = Math.random().toString(36).substring(2, 6);
    const storeSlug = `${baseSlug}-${randomSuffix}`;

    // Create Merchant and default Store transactionally
    const merchant = await this.db.merchant.create({
      data: {
        phone: normalizedPhone,
        fullName: dto.fullName,
        pinHash,
        securityQuestion: dto.securityQuestion,
        securityAnswerHash,
        backupEmail: dto.backupEmail,
        stores: {
          create: {
            name: storeName,
            slug: storeSlug,
            isPublic: false,
          },
        },
      },
      include: {
        stores: true,
      },
    });

    const tokens = await this.generateTokens(merchant.id, merchant.phone, merchant.role);

    return {
      message: 'Matagumpay na narehistro ang tindahan!',
      merchant: {
        id: merchant.id,
        phone: merchant.phone,
        fullName: merchant.fullName,
        role: merchant.role,
        hasSecurityQuestion: !!merchant.securityQuestion,
      },
      store: merchant.stores[0],
      ...tokens,
    };
  }

  async login(dto: LoginDto) {
    const normalizedPhone = this.normalizePhone(dto.phone);

    const merchant = await this.db.merchant.findUnique({
      where: { phone: normalizedPhone },
      include: { stores: true },
    });

    if (!merchant || !merchant.pinHash) {
      throw new UnauthorizedException('Maling numero ng telepono o Store PIN');
    }

    const isPinValid = await bcrypt.compare(dto.pin, merchant.pinHash);
    if (!isPinValid) {
      throw new UnauthorizedException('Maling numero ng telepono o Store PIN');
    }

    const tokens = await this.generateTokens(merchant.id, merchant.phone, merchant.role);

    return {
      message: 'Maligayang pagbabalik!',
      merchant: {
        id: merchant.id,
        phone: merchant.phone,
        fullName: merchant.fullName,
        role: merchant.role,
        hasSecurityQuestion: !!merchant.securityQuestion,
      },
      stores: merchant.stores,
      ...tokens,
    };
  }

  async recoverPin(dto: RecoverPinDto) {
    const normalizedPhone = this.normalizePhone(dto.phone);

    const merchant = await this.db.merchant.findUnique({
      where: { phone: normalizedPhone },
    });

    if (!merchant || !merchant.securityAnswerHash) {
      throw new BadRequestException(
        'Walang naitakdang secret security question para sa numerong ito. Mangyaring gumamit ng ibang paraan ng pagbawi.',
      );
    }

    // Verify security question matches
    if (merchant.securityQuestion !== dto.securityQuestion) {
      throw new BadRequestException('Maling security question');
    }

    // Verify answer
    const normalizedAnswer = dto.securityAnswer.trim().toLowerCase();
    const isAnswerValid = await bcrypt.compare(normalizedAnswer, merchant.securityAnswerHash);
    if (!isAnswerValid) {
      throw new UnauthorizedException('Maling sagot sa security question');
    }

    // Hash and update new PIN
    const newPinHash = await bcrypt.hash(dto.newPin, 10);
    await this.db.merchant.update({
      where: { id: merchant.id },
      data: { pinHash: newPinHash },
    });

    return {
      success: true,
      message: 'Matagumpay na nabago ang iyong Store PIN! Maaari ka nang mag-login gamit ang bagong PIN.',
    };
  }

  async refreshToken(refreshTokenString: string) {
    try {
      const payload = this.jwtService.verify(refreshTokenString, {
        secret: process.env.JWT_SECRET || 'tindagrid_super_secret_jwt_key_change_in_production',
      });

      const merchant = await this.db.merchant.findUnique({
        where: { id: payload.sub },
      });

      if (!merchant) {
        throw new UnauthorizedException('Hindi nahanap ang tindahan');
      }

      return this.generateTokens(merchant.id, merchant.phone, merchant.role);
    } catch {
      throw new UnauthorizedException('Expired o hindi wastong refresh token. Paki-type ang iyong PIN muli.');
    }
  }

  private async generateTokens(merchantId: string, phone: string, role: string) {
    const payload = { sub: merchantId, phone, role };
    const secret = process.env.JWT_SECRET || 'tindagrid_super_secret_jwt_key_change_in_production';

    const accessToken = this.jwtService.sign(payload, {
      secret,
      expiresIn: '30d',
    });

    const refreshToken = this.jwtService.sign(
      { sub: merchantId, type: 'refresh' },
      {
        secret,
        expiresIn: '365d',
      },
    );

    return {
      accessToken,
      refreshToken,
      expiresIn: '30d',
    };
  }
}
