import { NestFactory } from '@nestjs/core';
import { SyncServiceModule } from './sync-service.module.js';

async function bootstrap() {
  const app = await NestFactory.create(SyncServiceModule);
  const port = process.env.SYNC_SERVICE_PORT || process.env.PORT || process.env.port || 3001;
  await app.listen(port, '0.0.0.0');
}
await bootstrap();
