import { Controller, Get } from '@nestjs/common';
import { B2bAnalyticsServiceService } from './b2b-analytics-service.service.js';

@Controller()
export class B2bAnalyticsServiceController {
  constructor(private readonly b2bAnalyticsServiceService: B2bAnalyticsServiceService) {}

  @Get()
  getInfo() {
    return {
      service: 'b2b-analytics-service',
      port: 3004,
      status: 'online',
      description: 'Anonymized FMCG Market Share & Pricing Intelligence Engine',
    };
  }

  @Get('health')
  getHealth() {
    return { status: 'ok', service: 'b2b-analytics-service' };
  }
}
