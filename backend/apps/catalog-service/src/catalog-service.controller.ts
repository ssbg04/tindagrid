import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { CatalogServiceService } from './catalog-service.service.js';

@Controller('catalog')
export class CatalogServiceController {
  constructor(private readonly catalogService: CatalogServiceService) {}

  @Get()
  getInfo() {
    return {
      service: 'catalog-service',
      port: 3002,
      status: 'online',
      description: 'Master Philippine Barcode & Crowdsourced Product Catalog',
      endpoints: [
        'GET /catalog/barcode/:barcode',
        'POST /catalog/barcode/contribute',
        'GET /catalog/search?q=...',
      ],
    };
  }

  @Get('health')
  getHealth() {
    return { status: 'ok', service: 'catalog-service' };
  }

  @Get('barcode/:barcode')
  async lookupBarcode(@Param('barcode') barcode: string) {
    return this.catalogService.lookupBarcode(barcode);
  }

  @Post('barcode/contribute')
  async contributeBarcode(
    @Body()
    dto: {
      barcode: string;
      name: string;
      category?: string;
      defaultPrice?: number;
    },
  ) {
    return this.catalogService.contributeBarcode(dto);
  }

  @Get('search')
  async searchCatalog(@Query('q') query: string) {
    return this.catalogService.searchCatalog(query || '');
  }
}
