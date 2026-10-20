import { Test, TestingModule } from '@nestjs/testing';
import { CatalogServiceController } from './catalog-service.controller.js';
import { CatalogServiceService } from './catalog-service.service.js';
import { DatabaseService } from '../../../libs/database/src/database.service.js';

describe('CatalogServiceController', () => {
  let controller: CatalogServiceController;

  beforeEach(async () => {
    const mockDb = {
      globalBarcode: {
        findUnique: vi.fn().mockImplementation(({ where }) => {
          if (where.barcode === '4800016644819') {
            return Promise.resolve({
              barcode: '4800016644819',
              name: 'Lucky Me! Instant Pancit Canton Original 80g',
              category: 'Noodles',
              defaultPrice: 18.0,
              verifiedCount: 154,
            });
          }
          return Promise.resolve(null);
        }),
        create: vi.fn().mockImplementation(({ data }) => Promise.resolve({ ...data, verifiedCount: 1 })),
        update: vi.fn().mockImplementation(({ data }) => Promise.resolve({ ...data, verifiedCount: 2 })),
      },
    };

    const app: TestingModule = await Test.createTestingModule({
      controllers: [CatalogServiceController],
      providers: [
        CatalogServiceService,
        { provide: DatabaseService, useValue: mockDb },
      ],
    }).compile();

    controller = app.get<CatalogServiceController>(CatalogServiceController);
  });

  describe('root & health', () => {
    it('should return service info', () => {
      const info = controller.getInfo();
      expect(info.service).toBe('catalog-service');
      expect(info.status).toBe('online');
    });

    it('should return health ok', () => {
      const health = controller.getHealth();
      expect(health.status).toBe('ok');
    });
  });

  describe('crowdsourced barcode lookup & contribution', () => {
    it('should lookup known master barcode', async () => {
      const result = await controller.lookupBarcode('4800016644819');
      expect(result.found).toBe(true);
      expect(result.name).toContain('Lucky Me! Instant Pancit Canton');
      expect(result.defaultPrice).toBe(18.0);
    });

    it('should return found=false for unknown barcode', async () => {
      const result = await controller.lookupBarcode('9999999999999');
      expect(result.found).toBe(false);
    });

    it('should contribute new crowdsourced product barcode', async () => {
      const contributed = await controller.contributeBarcode({
        barcode: '4800019999999',
        name: 'Chocnut Peanut Bar 24s',
        category: 'Snacks',
        defaultPrice: 35.0,
      });

      expect(contributed.success).toBe(true);
      expect(contributed.barcode).toBe('4800019999999');
      expect(contributed.name).toBe('Chocnut Peanut Bar 24s');
    });

    it('should search catalog by product keyword', async () => {
      const items = await controller.searchCatalog('Pancit');
      expect(items.length).toBeGreaterThan(0);
      expect(items.some((item) => item.name.includes('Pancit'))).toBe(true);
    });
  });
});
