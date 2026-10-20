import { NestFactory } from '@nestjs/core';
import { CatalogServiceModule } from './catalog-service.module.js';

async function bootstrap() {
  const app = await NestFactory.create(CatalogServiceModule);
  const port = process.env.CATALOG_SERVICE_PORT || process.env.PORT || process.env.port || 3002;
  await app.listen(port, '0.0.0.0');
}
await bootstrap();
