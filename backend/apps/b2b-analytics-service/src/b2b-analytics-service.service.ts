import { Injectable, Logger } from '@nestjs/common';
import * as crypto from 'crypto';
import { DatabaseService } from '@lib/database';
import { GenerateApiKeyDto } from './dto/b2b.dto.js';

@Injectable()
export class B2bAnalyticsServiceService {
  private readonly logger = new Logger(B2bAnalyticsServiceService.name);

  constructor(private readonly db: DatabaseService) {}

  /**
   * Generates a new cryptographic B2B Partner API key.
   */
  async generateApiKey(dto: GenerateApiKeyDto) {
    const rawKey = `tg_live_${crypto.randomBytes(24).toString('hex')}`;
    const apiKeyHash = crypto
      .createHash('sha256')
      .update(rawKey)
      .digest('hex');

    const record = await this.db.b2bApiKey.create({
      data: {
        clientName: dto.clientName,
        apiKeyHash,
        tier: dto.tier || 'STANDARD',
        rateLimit: dto.rateLimit || 1000,
        isActive: true,
      },
    });

    return {
      apiKey: rawKey,
      keyId: record.id,
      clientName: record.clientName,
      tier: record.tier,
      rateLimit: record.rateLimit,
      message:
        'Store this API key safely in your secret manager. It will not be shown again.',
    };
  }

  /**
   * B2B Brand Velocity Insights:
   * Aggregates anonymized street-level sales data to compute consumer product velocity.
   */
  async getBrandVelocity(category?: string, limit: number = 20) {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const sales = await this.db.sale.findMany({
      where: {
        createdAt: { gte: thirtyDaysAgo },
      },
      select: {
        items: true,
        totalAmount: true,
        createdAt: true,
      },
      take: 1000,
    });

    const velocityMap = new Map<
      string,
      {
        productName: string;
        category: string;
        unitsSold: number;
        totalVolumePhp: number;
        transactionCount: number;
      }
    >();

    for (const s of sales) {
      if (!Array.isArray(s.items)) continue;

      for (const item of s.items as any[]) {
        if (!item || !item.name) continue;
        const itemCategory = item.category || 'General';

        if (
          category &&
          !itemCategory.toLowerCase().includes(category.toLowerCase())
        ) {
          continue;
        }

        const key = item.name.toLowerCase().trim();
        const existing = velocityMap.get(key) || {
          productName: item.name,
          category: itemCategory,
          unitsSold: 0,
          totalVolumePhp: 0,
          transactionCount: 0,
        };

        const qty = Number(item.quantity || 1);
        const price = Number(item.price || item.sellingPrice || 0);

        existing.unitsSold += qty;
        existing.totalVolumePhp += qty * price;
        existing.transactionCount += 1;
        velocityMap.set(key, existing);
      }
    }

    const aggregated = Array.from(velocityMap.values())
      .sort((a, b) => b.unitsSold - a.unitsSold)
      .slice(0, limit);

    return {
      period: 'last_30_days',
      categoryFilter: category || 'all',
      totalSalesSampled: sales.length,
      topVelocityProducts: aggregated,
    };
  }

  /**
   * Cross-Store Street Pricing Intelligence:
   * Computes min, max, and average retail prices across neighborhood sari-sari stores.
   */
  async getPricingBenchmarks(
    barcode?: string,
    category?: string,
    limit: number = 20,
  ) {
    const products = await this.db.product.findMany({
      where: {
        isDeleted: false,
        ...(barcode && { barcode }),
        ...(category && {
          category: { contains: category, mode: 'insensitive' },
        }),
      },
      select: {
        barcode: true,
        name: true,
        category: true,
        sellingPrice: true,
        costPrice: true,
        isTingi: true,
      },
      take: 2000,
    });

    const benchmarkMap = new Map<
      string,
      {
        identifier: string;
        name: string;
        category: string | null;
        prices: number[];
        costs: number[];
        sampleStoresCount: number;
      }
    >();

    for (const p of products) {
      const key = p.barcode || p.name.toLowerCase().trim();
      const existing = benchmarkMap.get(key) || {
        identifier: key,
        name: p.name,
        category: p.category,
        prices: [],
        costs: [],
        sampleStoresCount: 0,
      };

      existing.prices.push(p.sellingPrice);
      if (p.costPrice > 0) existing.costs.push(p.costPrice);
      existing.sampleStoresCount += 1;
      benchmarkMap.set(key, existing);
    }

    const benchmarks = Array.from(benchmarkMap.values())
      .map((b) => {
        const sorted = [...b.prices].sort((a, b) => a - b);
        const minPrice = sorted[0] || 0;
        const maxPrice = sorted[sorted.length - 1] || 0;
        const avgPrice =
          sorted.reduce((acc, val) => acc + val, 0) / (sorted.length || 1);
        const medianPrice = sorted[Math.floor(sorted.length / 2)] || 0;

        const avgCost =
          b.costs.length > 0
            ? b.costs.reduce((acc, val) => acc + val, 0) / b.costs.length
            : null;

        return {
          barcodeOrKey: b.identifier,
          productName: b.name,
          category: b.category,
          sampleCount: b.sampleStoresCount,
          minPrice: Math.round(minPrice * 100) / 100,
          maxPrice: Math.round(maxPrice * 100) / 100,
          avgPrice: Math.round(avgPrice * 100) / 100,
          medianPrice: Math.round(medianPrice * 100) / 100,
          estimatedMerchantMarginPercent:
            avgCost && avgPrice > 0
              ? Math.round(((avgPrice - avgCost) / avgPrice) * 1000) / 10
              : null,
        };
      })
      .sort((a, b) => b.sampleCount - a.sampleCount)
      .slice(0, limit);

    return {
      totalProductsAnalyzed: products.length,
      benchmarks,
    };
  }

  /**
   * Tingi (Sachet / Single-piece) vs Packaged Ratio Metrics:
   * Provides FMCG brand packaging teams visibility into street portioning behavior.
   */
  async getTingiRatio() {
    const totalCount = await this.db.product.count({
      where: { isDeleted: false },
    });
    const tingiCount = await this.db.product.count({
      where: { isDeleted: false, isTingi: true },
    });
    const standardCount = totalCount - tingiCount;

    const tingiPercentage =
      totalCount > 0 ? Math.round((tingiCount / totalCount) * 1000) / 10 : 0;

    return {
      totalCatalogedProducts: totalCount,
      tingiProductsCount: tingiCount,
      standardPackagedCount: standardCount,
      tingiRatioPercentage: tingiPercentage,
      insight:
        tingiPercentage > 40
          ? 'High micro-transaction portioning detected. Sachet packaging dominates retail volume.'
          : 'Moderate tingi adoption.',
    };
  }
}
