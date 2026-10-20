export class GenerateApiKeyDto {
  clientName!: string;
  tier?: 'STANDARD' | 'ENTERPRISE';
  rateLimit?: number;
}

export class BrandVelocityQueryDto {
  category?: string;
  limit?: number;
}

export class PricingBenchmarkQueryDto {
  barcode?: string;
  category?: string;
  limit?: number;
}
