import { Module } from '@nestjs/common';
import { DatabaseModule } from '@lib/database';
import { CommonModule } from '@lib/common';
import { B2bAnalyticsServiceController } from './b2b-analytics-service.controller.js';
import { B2bAnalyticsServiceService } from './b2b-analytics-service.service.js';

@Module({
  imports: [DatabaseModule, CommonModule],
  controllers: [B2bAnalyticsServiceController],
  providers: [B2bAnalyticsServiceService],
  exports: [B2bAnalyticsServiceService],
})
export class B2bAnalyticsServiceModule {}
