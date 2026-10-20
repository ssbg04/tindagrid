import { Module } from '@nestjs/common';
import { DatabaseModule } from '@lib/database';
import { CommonModule } from '@lib/common';
import { StorefrontServiceController } from './storefront-service.controller.js';
import { StorefrontServiceService } from './storefront-service.service.js';

@Module({
  imports: [DatabaseModule, CommonModule],
  controllers: [StorefrontServiceController],
  providers: [StorefrontServiceService],
  exports: [StorefrontServiceService],
})
export class StorefrontServiceModule {}
