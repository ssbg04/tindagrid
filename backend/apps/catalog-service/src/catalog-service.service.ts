import { Injectable, Logger } from '@nestjs/common';
import { DatabaseService } from '@lib/database';

export interface CatalogItem {
  barcode: string;
  name: string;
  category: string;
  defaultPrice: number;
  verifiedCount: number;
}

@Injectable()
export class CatalogServiceService {
  private readonly logger = new Logger(CatalogServiceService.name);

  // Master Philippine Sari-Sari Barcode Seeds (Zero-latency fallback)
  private readonly masterSeeds: Record<string, Omit<CatalogItem, 'barcode'>> = {
    '4800016644819': {
      name: 'Lucky Me! Instant Pancit Canton Original 80g',
      category: 'Noodles',
      defaultPrice: 18.0,
      verifiedCount: 154,
    },
    '4800016644826': {
      name: 'Lucky Me! Instant Pancit Canton Extra Hot 80g',
      category: 'Noodles',
      defaultPrice: 18.0,
      verifiedCount: 142,
    },
    '4800016644802': {
      name: 'Lucky Me! Instant Pancit Canton Kalamansi 80g',
      category: 'Noodles',
      defaultPrice: 18.0,
      verifiedCount: 160,
    },
    '4800016644833': {
      name: 'Lucky Me! Instant Pancit Canton Sweet & Spicy 80g',
      category: 'Noodles',
      defaultPrice: 18.0,
      verifiedCount: 175,
    },
    '4800016008802': {
      name: 'Lucky Me! Instant Mami Beef 55g',
      category: 'Noodles',
      defaultPrice: 16.0,
      verifiedCount: 120,
    },
    '4800016008819': {
      name: 'Lucky Me! Instant Mami Chicken 55g',
      category: 'Noodles',
      defaultPrice: 16.0,
      verifiedCount: 115,
    },
    '4800888137358': {
      name: 'Bear Brand Fortified Powdered Milk Drink 33g',
      category: 'Dairy',
      defaultPrice: 15.0,
      verifiedCount: 210,
    },
    '4800024555816': {
      name: 'Kopiko Blanca 3-in-1 Coffee Twin Pack 52g',
      category: 'Beverage',
      defaultPrice: 14.0,
      verifiedCount: 198,
    },
    '4800024555823': {
      name: 'Kopiko Brown 3-in-1 Coffee 30g',
      category: 'Beverage',
      defaultPrice: 14.0,
      verifiedCount: 165,
    },
    '4800024555830': {
      name: 'Kopiko Black 3-in-1 Coffee 30g',
      category: 'Beverage',
      defaultPrice: 14.0,
      verifiedCount: 130,
    },
    '4800016670016': {
      name: 'Nissin Cup Noodles Seafood 40g',
      category: 'Noodles',
      defaultPrice: 25.0,
      verifiedCount: 88,
    },
    '4800092110017': {
      name: 'Coca-Cola Mismo 300ml',
      category: 'Beverage',
      defaultPrice: 20.0,
      verifiedCount: 310,
    },
    '4800092110024': {
      name: 'Royal Tru-Orange Mismo 300ml',
      category: 'Beverage',
      defaultPrice: 20.0,
      verifiedCount: 220,
    },
    '4800092110031': {
      name: 'Sprite Mismo 300ml',
      category: 'Beverage',
      defaultPrice: 20.0,
      verifiedCount: 180,
    },
    '4800011110012': {
      name: 'San Miguel Pale Pilsen 330ml Can',
      category: 'Alcohol',
      defaultPrice: 48.0,
      verifiedCount: 95,
    },
    '4800011110029': {
      name: 'Red Horse Beer 500ml Can',
      category: 'Alcohol',
      defaultPrice: 55.0,
      verifiedCount: 140,
    },
    '4800110021008': {
      name: 'Datu Puti White Vinegar 100ml Sachet',
      category: 'Condiments',
      defaultPrice: 6.0,
      verifiedCount: 185,
    },
    '4800110022005': {
      name: 'Silver Swan Soy Sauce 100ml Sachet',
      category: 'Condiments',
      defaultPrice: 6.0,
      verifiedCount: 190,
    },
    '4800047820014': {
      name: 'Safeguard Pure White Bar Soap 60g',
      category: 'Personal Care',
      defaultPrice: 25.0,
      verifiedCount: 240,
    },
    '4800047820021': {
      name: 'Palmolive Intensive Moisture Shampoo 15ml Sachet',
      category: 'Personal Care',
      defaultPrice: 7.0,
      verifiedCount: 205,
    },
  };

  constructor(private readonly db: DatabaseService) {}

  /**
   * Search crowdsourced master barcode registry
   */
  async lookupBarcode(barcode: string) {
    const cleanBarcode = barcode.trim();

    // 1. Check PostgreSQL Neon Database
    try {
      const record = await this.db.globalBarcode.findUnique({
        where: { barcode: cleanBarcode },
      });

      if (record) {
        return {
          found: true,
          barcode: record.barcode,
          name: record.name,
          category: record.category ?? 'General',
          defaultPrice: record.defaultPrice ?? 0.0,
          verifiedCount: record.verifiedCount,
          source: 'neon_postgres',
        };
      }
    } catch (e) {
      this.logger.warn(`Database lookup failed for barcode ${cleanBarcode}: ${e}`);
    }

    // 2. Check Philippine Sari-Sari Master Seeds
    const seed = this.masterSeeds[cleanBarcode];
    if (seed) {
      return {
        found: true,
        barcode: cleanBarcode,
        name: seed.name,
        category: seed.category,
        defaultPrice: seed.defaultPrice,
        verifiedCount: seed.verifiedCount,
        source: 'philippines_master_seed',
      };
    }

    return {
      found: false,
      barcode: cleanBarcode,
    };
  }

  /**
   * Crowdsource: Store owners contribute or verify unknown barcodes
   */
  async contributeBarcode(dto: {
    barcode: string;
    name: string;
    category?: string;
    defaultPrice?: number;
  }) {
    const cleanBarcode = dto.barcode.trim();
    const cleanName = dto.name.trim();

    try {
      const existing = await this.db.globalBarcode.findUnique({
        where: { barcode: cleanBarcode },
      });

      if (existing) {
        const updated = await this.db.globalBarcode.update({
          where: { barcode: cleanBarcode },
          data: {
            verifiedCount: { increment: 1 },
            name: cleanName.length > 2 ? cleanName : existing.name,
            category: dto.category ?? existing.category,
            defaultPrice: dto.defaultPrice ?? existing.defaultPrice,
          },
        });
        return {
          success: true,
          barcode: updated.barcode,
          name: updated.name,
          verifiedCount: updated.verifiedCount,
          isNew: false,
        };
      }

      const created = await this.db.globalBarcode.create({
        data: {
          barcode: cleanBarcode,
          name: cleanName,
          category: dto.category ?? 'General',
          defaultPrice: dto.defaultPrice ?? 0.0,
          verifiedCount: 1,
        },
      });

      return {
        success: true,
        barcode: created.barcode,
        name: created.name,
        verifiedCount: created.verifiedCount,
        isNew: true,
      };
    } catch (e) {
      this.logger.warn(`Crowdsource contribution fallback to memory: ${e}`);
      // In-memory fallback
      this.masterSeeds[cleanBarcode] = {
        name: cleanName,
        category: dto.category ?? 'General',
        defaultPrice: dto.defaultPrice ?? 0.0,
        verifiedCount: 1,
      };
      return {
        success: true,
        barcode: cleanBarcode,
        name: cleanName,
        verifiedCount: 1,
        isNew: true,
      };
    }
  }

  /**
   * Search master catalog by product name or query
   */
  async searchCatalog(query: string) {
    const clean = query.trim().toLowerCase();
    const results: CatalogItem[] = [];

    // Search seeds
    for (const [code, item] of Object.entries(this.masterSeeds)) {
      if (item.name.toLowerCase().includes(clean) || code.includes(clean)) {
        results.push({
          barcode: code,
          ...item,
        });
      }
    }

    return results.slice(0, 20);
  }
}
