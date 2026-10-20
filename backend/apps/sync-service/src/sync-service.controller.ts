import { Controller, Get } from '@nestjs/common';
import { SyncServiceService } from './sync-service.service.js';

@Controller()
export class SyncServiceController {
  constructor(private readonly syncServiceService: SyncServiceService) {}

  @Get()
  getInfo() {
    return {
      service: 'sync-service',
      port: 3001,
      status: 'online',
      description: 'Delta Synchronization & Offline Replication Engine',
    };
  }

  @Get('health')
  getHealth() {
    return { status: 'ok', service: 'sync-service' };
  }
}
