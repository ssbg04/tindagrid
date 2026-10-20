import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { B2bAnalyticsServiceService } from './b2b-analytics-service.service.js';
import {
  GenerateApiKeyDto,
  BrandVelocityQueryDto,
  PricingBenchmarkQueryDto,
} from './dto/b2b.dto.js';
import { B2bApiKeyGuard } from './guards/b2b-api-key.guard.js';
import {
  RateLimit,
  RateLimitGuard,
  LoggingInterceptor,
} from '@lib/common';


@Controller('b2b')
@UseInterceptors(LoggingInterceptor)
export class B2bAnalyticsServiceController {
  constructor(
    private readonly b2bAnalyticsService: B2bAnalyticsServiceService,
  ) {}

  @Get()
  getInfo() {
    return {
      service: 'b2b-analytics-service',
      port: 3004,
      status: 'online',
      description: 'Anonymized FMCG Market Share & Pricing Intelligence Engine',
      authMethod: 'HTTP Header X-API-Key: tg_live_...',
      endpoints: [
        'GET /b2b/insights/brand-velocity?category=...&limit=...',
        'GET /b2b/insights/pricing-benchmarks?barcode=...&category=...',
        'GET /b2b/insights/tingi-ratio',
        'POST /b2b/keys/generate',
      ],
    };
  }

  @Get('health')
  getHealth() {
    return { status: 'ok', service: 'b2b-analytics-service' };
  }

  /**
   * Admin / Partner Key Generation.
   */
  @Post('keys/generate')
  async generateApiKey(@Body() dto: GenerateApiKeyDto) {
    return this.b2bAnalyticsService.generateApiKey(dto);
  }

  /**
   * FMCG Brand Velocity Data Feed.
   * Protected with B2bApiKeyGuard and RateLimitGuard.
   */
  @Get('insights/brand-velocity')
  @UseGuards(B2bApiKeyGuard, RateLimitGuard)
  @RateLimit(120, 60000)
  async getBrandVelocity(@Query() query: BrandVelocityQueryDto) {
    const limit = query.limit ? Number(query.limit) : 20;
    return this.b2bAnalyticsService.getBrandVelocity(query.category, limit);
  }

  /**
   * FMCG Cross-Store Street Pricing Benchmarks.
   * Protected with B2bApiKeyGuard and RateLimitGuard.
   */
  @Get('insights/pricing-benchmarks')
  @UseGuards(B2bApiKeyGuard, RateLimitGuard)
  @RateLimit(120, 60000)
  async getPricingBenchmarks(@Query() query: PricingBenchmarkQueryDto) {
    const limit = query.limit ? Number(query.limit) : 20;
    return this.b2bAnalyticsService.getPricingBenchmarks(
      query.barcode,
      query.category,
      limit,
    );
  }

  /**
   * Tingi (Sachet) Packaging Ratio Metrics.
   * Protected with B2bApiKeyGuard and RateLimitGuard.
   */
  @Get('insights/tingi-ratio')
  @UseGuards(B2bApiKeyGuard, RateLimitGuard)
  @RateLimit(120, 60000)
  async getTingiRatio() {
    return this.b2bAnalyticsService.getTingiRatio();
  }
}
