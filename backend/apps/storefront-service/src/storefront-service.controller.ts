import { Controller, Get } from '@nestjs/common';
import { StorefrontServiceService } from './storefront-service.service.js';

@Controller('storefront')
export class StorefrontServiceController {
  constructor(private readonly storefrontServiceService: StorefrontServiceService) {}

  @Get()
  getInfo() {
    return {
      service: 'storefront-service',
      port: 3003,
      status: 'online',
      description: 'Public Web Storefront & Customer Ordering Engine',
    };
  }

  @Get('health')
  getHealth() {
    return { status: 'ok', service: 'storefront-service' };
  }
}
