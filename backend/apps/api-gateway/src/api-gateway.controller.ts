import { Controller, Get } from '@nestjs/common';
import { ApiGatewayService } from './api-gateway.service.js';
import { DatabaseService } from '@lib/database';

@Controller()
export class ApiGatewayController {
  constructor(
    private readonly apiGatewayService: ApiGatewayService,
    private readonly db: DatabaseService,
  ) {}

  @Get()
  getHello(): string {
    return this.apiGatewayService.getHello();
  }

  @Get('health')
  async getHealth() {
    let dbStatus = 'connected';
    try {
      await this.db.$queryRaw`SELECT 1`;
    } catch (err: any) {
      dbStatus = `disconnected: ${err.message}`;
    }

    return {
      status: dbStatus === 'connected' ? 'ok' : 'degraded',
      service: 'api-gateway',
      database: dbStatus,
      services: {
        sync: 'active (/sync)',
        catalog: 'active (/catalog)',
        storefront: 'active (/storefront)',
        b2b: 'active (/b2b)',
      },
      timestamp: new Date().toISOString(),
    };
  }
}
