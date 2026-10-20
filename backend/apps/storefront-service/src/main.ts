import { NestFactory } from '@nestjs/core';
import { StorefrontServiceModule } from './storefront-service.module.js';

async function bootstrap() {
  const app = await NestFactory.create(StorefrontServiceModule);
  const port = process.env.STOREFRONT_SERVICE_PORT || process.env.PORT || process.env.port || 3003;
  await app.listen(port, '0.0.0.0');
}
await bootstrap();
