import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Req,
} from '@nestjs/common';
import { SyncServiceService } from './sync-service.service.js';
import { SyncAuthGuard } from './guards/sync-auth.guard.js';
import { PushSyncDto } from './dto/sync.dto.js';

@Controller('sync')
export class SyncServiceController {
  constructor(private readonly syncService: SyncServiceService) {}

  @Get()
  getInfo() {
    return {
      service: 'sync-service',
      port: 3001,
      status: 'online',
      description: 'Delta Synchronization & Offline Replication Engine',
      endpoints: [
        'POST /sync/push',
        'GET /sync/pull',
        'GET /sync/restore',
      ],
    };
  }

  @Get('health')
  getHealth() {
    return { status: 'ok', service: 'sync-service' };
  }

  @Post('push')
  @UseGuards(SyncAuthGuard)
  async pushMutations(@Req() req: any, @Body() dto: PushSyncDto) {
    const merchantId = req.merchant.sub;
    return this.syncService.pushMutations(merchantId, dto.storeId, dto.mutations);
  }

  @Get('pull')
  @UseGuards(SyncAuthGuard)
  async pullDeltas(
    @Req() req: any,
    @Query('storeId') storeId?: string,
    @Query('since') since?: string,
  ) {
    const merchantId = req.merchant.sub;
    return this.syncService.pullDeltas(merchantId, storeId, since);
  }

  @Get('restore')
  @UseGuards(SyncAuthGuard)
  async restoreFullStore(
    @Req() req: any,
    @Query('storeId') storeId?: string,
  ) {
    const merchantId = req.merchant.sub;
    return this.syncService.restoreFullStore(merchantId, storeId);
  }

  // --- Companion Scanner Endpoints ---

  @Post('companion/session')
  async createCompanionSession(@Body() body?: { storeId?: string }) {
    return this.syncService.createCompanionSession(undefined, body?.storeId);
  }

  @Post('companion/scan')
  async pushCompanionScan(@Body() body: { sessionId: string; barcode: string }) {
    return this.syncService.pushCompanionScan(body.sessionId, body.barcode);
  }

  @Get('companion/poll')
  async pollCompanionScans(
    @Query('sessionId') sessionId: string,
    @Query('sinceScanId') sinceScanId?: string,
  ) {
    return this.syncService.pollCompanionScans(sessionId, sinceScanId);
  }
}
