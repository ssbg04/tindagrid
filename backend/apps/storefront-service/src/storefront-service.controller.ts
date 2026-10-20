import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { StorefrontServiceService } from './storefront-service.service.js';
import { UpdateStorefrontDto } from './dto/storefront.dto.js';
import { LoggingInterceptor, RateLimit, RateLimitGuard } from '@lib/common';

@Controller('storefront')
@UseInterceptors(LoggingInterceptor)
@UseGuards(RateLimitGuard)
export class StorefrontServiceController {
  constructor(private readonly storefrontService: StorefrontServiceService) {}

  @Get()
  getInfo() {
    return {
      service: 'storefront-service',
      port: 3003,
      status: 'online',
      description: 'Public Web Storefront & PostGIS Spatial Discovery Engine',
      endpoints: [
        'GET /storefront/nearby?lat=...&lng=...&radiusMeters=...',
        'GET /storefront/:slug',
        'GET /storefront/:slug/products',
        'POST /storefront/:storeId/upload-url',
        'PATCH /storefront/:storeId',
      ],
    };
  }

  @Get('health')
  getHealth() {
    return { status: 'ok', service: 'storefront-service' };
  }

  /**
   * PostGIS Spatial Query: Finds nearby public stores.
   * Rate-limited to 60 req/min to protect database from scrapers.
   */
  @Get('nearby')
  @RateLimit(60, 60000)
  async findNearby(
    @Query('lat') latStr: string,
    @Query('lng') lngStr: string,
    @Query('radiusMeters') radiusStr?: string,
    @Query('limit') limitStr?: string,
  ) {
    const lat = parseFloat(latStr);
    const lng = parseFloat(lngStr);
    const radiusMeters = radiusStr ? parseFloat(radiusStr) : 5000;
    const limit = limitStr ? parseInt(limitStr, 10) : 20;

    return this.storefrontService.findNearbyStores(lat, lng, radiusMeters, limit);
  }

  /**
   * Retrieves public storefront by URL slug (e.g. tindagrid.com/aling-nena).
   */
  @Get(':slug')
  async getStoreBySlug(@Param('slug') slug: string) {
    return this.storefrontService.getStoreBySlug(slug);
  }

  /**
   * Retrieves active, in-stock products for public customer browsing.
   */
  @Get(':slug/products')
  async getStoreProducts(@Param('slug') slug: string) {
    return this.storefrontService.getStoreProducts(slug);
  }

  /**
   * Requests a pre-signed Cloudflare R2 upload URL for storefront cover photo.
   */
  @Post(':storeId/upload-url')
  async getPhotoUploadUrl(
    @Param('storeId') storeId: string,
    @Body('contentType') contentType?: string,
  ) {
    return this.storefrontService.getPhotoUploadUrl(storeId, contentType);
  }

  /**
   * Updates store profile, GPS coordinates, or public visibility toggle.
   */
  @Patch(':storeId')
  async updateStorefront(
    @Param('storeId') storeId: string,
    @Body() dto: UpdateStorefrontDto,
  ) {
    return this.storefrontService.updateStorefront(storeId, dto);
  }
}
