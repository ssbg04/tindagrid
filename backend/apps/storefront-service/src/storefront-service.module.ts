import { Module } from '@nestjs/common';
import { StorefrontServiceController } from './storefront-service.controller.js';
import { StorefrontServiceService } from './storefront-service.service.js';

@Module({
  imports: [],
  controllers: [StorefrontServiceController],
  providers: [StorefrontServiceService],
})
export class StorefrontServiceModule {}
