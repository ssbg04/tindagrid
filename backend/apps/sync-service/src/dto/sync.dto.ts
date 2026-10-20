import { IsString, IsArray, IsOptional, IsObject } from 'class-validator';

export class SyncMutationDto {
  @IsString()
  id: string; // sync_queue UUID

  @IsString()
  entityTable: string; // 'products' | 'sales' | 'debts' | 'inventory_logs' | 'gcash_ledger'

  @IsString()
  entityId: string;

  @IsString()
  operation: string; // 'INSERT' | 'UPDATE' | 'UPSERT' | 'DELETE'

  @IsObject()
  payload: any;

  @IsOptional()
  @IsString()
  clientTimestamp?: string;
}

export class PushSyncDto {
  @IsOptional()
  @IsString()
  storeId?: string;

  @IsArray()
  mutations: SyncMutationDto[];
}

export class CreateCompanionSessionDto {
  @IsOptional()
  @IsString()
  storeId?: string;
}

export class PushCompanionScanDto {
  @IsString()
  sessionId: string;

  @IsString()
  barcode: string;
}

