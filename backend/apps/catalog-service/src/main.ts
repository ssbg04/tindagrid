import { NestFactory } from '@nestjs/core';
import { CatalogServiceModule } from './catalog-service.module.js';

async function bootstrap() {
  const app = await NestFactory.create(CatalogServiceModule);
  const port = process.env.CATALOG_SERVICE_PORT || 3002;
  await app.listen(port, '0.0.0.0');
  console.log(`[catalog-service] Running on http://localhost:${port}`);
}
await bootstrap();
