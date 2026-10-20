import { NestFactory } from '@nestjs/core';
import { B2bAnalyticsServiceModule } from './b2b-analytics-service.module.js';

async function bootstrap() {
  const app = await NestFactory.create(B2bAnalyticsServiceModule);
  const port = process.env.B2B_SERVICE_PORT || 3004;
  await app.listen(port, '0.0.0.0');
  console.log(`[b2b-analytics-service] Running on http://localhost:${port}`);
}
await bootstrap();
