import { Module } from '@nestjs/common';
import { DatabaseModule } from '@lib/database';
import { CatalogServiceController } from './catalog-service.controller.js';
import { CatalogServiceService } from './catalog-service.service.js';

@Module({
  imports: [DatabaseModule],
  controllers: [CatalogServiceController],
  providers: [CatalogServiceService],
  exports: [CatalogServiceService],
})
export class CatalogServiceModule {}
