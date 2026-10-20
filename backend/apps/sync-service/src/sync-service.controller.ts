import { Controller, Get } from '@nestjs/common';
import { SyncServiceService } from './sync-service.service.js';

@Controller()
export class SyncServiceController {
  constructor(private readonly syncServiceService: SyncServiceService) {}

  @Get()
  getHello(): string {
    return this.syncServiceService.getHello();
  }
}
