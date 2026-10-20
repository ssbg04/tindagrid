import { Module } from '@nestjs/common';
import { SyncServiceController } from './sync-service.controller.js';
import { SyncServiceService } from './sync-service.service.js';

@Module({
  imports: [],
  controllers: [SyncServiceController],
  providers: [SyncServiceService],
})
export class SyncServiceModule {}
