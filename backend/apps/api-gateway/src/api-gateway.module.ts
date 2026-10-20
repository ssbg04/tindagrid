import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from '@lib/database';
import { validateEnv } from '@lib/common';
import { ApiGatewayController } from './api-gateway.controller.js';
import { ApiGatewayService } from './api-gateway.service.js';
import { SyncServiceModule } from '../../sync-service/src/sync-service.module.js';
import { CatalogServiceModule } from '../../catalog-service/src/catalog-service.module.js';
import { StorefrontServiceModule } from '../../storefront-service/src/storefront-service.module.js';
import { B2bAnalyticsServiceModule } from '../../b2b-analytics-service/src/b2b-analytics-service.module.js';
import { AuthModule } from './auth/auth.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
    }),
    DatabaseModule,
    AuthModule,
    SyncServiceModule,
    CatalogServiceModule,
    StorefrontServiceModule,
    B2bAnalyticsServiceModule,
  ],
  controllers: [ApiGatewayController],
  providers: [ApiGatewayService],
})
export class ApiGatewayModule {}
