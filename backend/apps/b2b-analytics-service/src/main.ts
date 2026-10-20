import { NestFactory } from '@nestjs/core';
import { B2bAnalyticsServiceModule } from './b2b-analytics-service.module.js';

async function bootstrap() {
  const app = await NestFactory.create(B2bAnalyticsServiceModule);
  await app.listen(process.env.port ?? 3000);
}
await bootstrap();
