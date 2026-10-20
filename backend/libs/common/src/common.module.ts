import { Module, Global } from '@nestjs/common';
import { CommonService } from './common.service.js';
import { R2StorageService } from './storage/r2-storage.service.js';

@Global()
@Module({
  providers: [CommonService, R2StorageService],
  exports: [CommonService, R2StorageService],
})
export class CommonModule {}
