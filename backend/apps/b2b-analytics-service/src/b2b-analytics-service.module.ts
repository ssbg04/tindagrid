import { Module } from '@nestjs/common';
import { B2bAnalyticsServiceController } from './b2b-analytics-service.controller.js';
import { B2bAnalyticsServiceService } from './b2b-analytics-service.service.js';

@Module({
  imports: [],
  controllers: [B2bAnalyticsServiceController],
  providers: [B2bAnalyticsServiceService],
})
export class B2bAnalyticsServiceModule {}
