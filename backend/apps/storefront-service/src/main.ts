import { NestFactory } from '@nestjs/core';
import { StorefrontServiceModule } from './storefront-service.module.js';

async function bootstrap() {
  const app = await NestFactory.create(StorefrontServiceModule);
  await app.listen(process.env.port ?? 3000);
}
await bootstrap();
