import { NestFactory } from '@nestjs/core';
import { StorefrontServiceModule } from './storefront-service.module.js';

async function bootstrap() {
  const app = await NestFactory.create(StorefrontServiceModule);
  const port = process.env.STOREFRONT_SERVICE_PORT || 3003;
  await app.listen(port, '0.0.0.0');
  console.log(`[storefront-service] Running on http://localhost:${port}`);
}
await bootstrap();
