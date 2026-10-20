import { Module, Global } from '@nestjs/common';
import { CommonService } from './common.service.js';
import { R2StorageService } from './storage/r2-storage.service.js';
import { LoggingInterceptor } from './interceptors/logging.interceptor.js';
import { RateLimitGuard } from './guards/rate-limit.guard.js';

@Global()
@Module({
  providers: [CommonService, R2StorageService, LoggingInterceptor, RateLimitGuard],
  exports: [CommonService, R2StorageService, LoggingInterceptor, RateLimitGuard],
})
export class CommonModule {}

