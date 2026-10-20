import { Controller, Get } from '@nestjs/common';
import { CatalogServiceService } from './catalog-service.service.js';

@Controller()
export class CatalogServiceController {
  constructor(private readonly catalogServiceService: CatalogServiceService) {}

  @Get()
  getInfo() {
    return {
      service: 'catalog-service',
      port: 3002,
      status: 'online',
      description: 'Master Philippine Barcode & Product Catalog',
    };
  }

  @Get('health')
  getHealth() {
    return { status: 'ok', service: 'catalog-service' };
  }
}
