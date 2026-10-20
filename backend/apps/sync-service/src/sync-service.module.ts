import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { DatabaseModule } from '@lib/database';
import { SyncServiceController } from './sync-service.controller.js';
import { SyncServiceService } from './sync-service.service.js';
import { SyncAuthGuard } from './guards/sync-auth.guard.js';

@Module({
  imports: [
    DatabaseModule,
    JwtModule.register({
      secret:
        process.env.JWT_SECRET ||
        'tindagrid_super_secret_jwt_key_change_in_production',
      signOptions: { expiresIn: '30d' },
    }),
  ],
  controllers: [SyncServiceController],
  providers: [SyncServiceService, SyncAuthGuard],
  exports: [SyncServiceService],
})
export class SyncServiceModule {}
