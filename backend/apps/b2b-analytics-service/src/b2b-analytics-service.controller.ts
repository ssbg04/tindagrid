import { Controller, Get } from '@nestjs/common';
import { B2bAnalyticsServiceService } from './b2b-analytics-service.service.js';

@Controller()
export class B2bAnalyticsServiceController {
  constructor(private readonly b2bAnalyticsServiceService: B2bAnalyticsServiceService) {}

  @Get()
  getHello(): string {
    return this.b2bAnalyticsServiceService.getHello();
  }
}
