import { plainToInstance } from 'class-transformer';
import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  validateSync,
} from 'class-validator';

enum Environment {
  Development = 'development',
  Production = 'production',
  Test = 'test',
}

export class EnvironmentVariables {
  @IsEnum(Environment)
  @IsOptional()
  NODE_ENV: Environment = Environment.Development;

  @IsNumber()
  @IsOptional()
  PORT: number = 3000;

  @IsString()
  DATABASE_URL!: string;

  @IsString()
  @IsOptional()
  JWT_SECRET: string = 'tindagrid_super_secret_jwt_key';

  @IsString()
  @IsOptional()
  JWT_EXPIRES_IN: string = '30d';

  @IsString()
  @IsOptional()
  CLOUDFLARE_R2_BUCKET_NAME: string = 'tindagrid-storefronts';
}

export function validateEnv(config: Record<string, unknown>) {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    throw new Error(`[TindaGrid Config Error] ${errors.toString()}`);
  }

  return validatedConfig;
}
