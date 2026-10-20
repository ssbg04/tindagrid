import { Test, TestingModule } from '@nestjs/testing';
import { B2bAnalyticsServiceController } from './b2b-analytics-service.controller.js';
import { B2bAnalyticsServiceService } from './b2b-analytics-service.service.js';
import { DatabaseService } from '../../../libs/database/src/database.service.js';

describe('B2bAnalyticsServiceController', () => {
  let controller: B2bAnalyticsServiceController;
  let service: B2bAnalyticsServiceService;

  const mockDb = {
    b2bApiKey: {
      create: vi.fn(),
      findUnique: vi.fn(),
    },
    sale: {
      findMany: vi.fn(),
    },
    product: {
      findMany: vi.fn(),
      count: vi.fn(),
    },
  };

  beforeEach(async () => {
    vi.clearAllMocks();
    const app: TestingModule = await Test.createTestingModule({
      controllers: [B2bAnalyticsServiceController],
      providers: [
        B2bAnalyticsServiceService,
        { provide: DatabaseService, useValue: mockDb },
      ],
    }).compile();

    controller = app.get<B2bAnalyticsServiceController>(
      B2bAnalyticsServiceController,
    );
    service = app.get<B2bAnalyticsServiceService>(B2bAnalyticsServiceService);
  });

  describe('root & health', () => {
    it('should return service info', () => {
      const info = controller.getInfo();
      expect(info.service).toBe('b2b-analytics-service');
      expect(info.status).toBe('online');
      expect(info.endpoints.length).toBeGreaterThan(0);
    });

    it('should return health status', () => {
      const health = controller.getHealth();
      expect(health.status).toBe('ok');
    });
  });

  describe('generateApiKey', () => {
    it('should issue a hashed API key for FMCG partners', async () => {
      mockDb.b2bApiKey.create.mockResolvedValue({
        id: 'key-uuid-1',
        clientName: 'Unilever Philippines',
        tier: 'ENTERPRISE',
        rateLimit: 5000,
      });

      const res = await controller.generateApiKey({
        clientName: 'Unilever Philippines',
        tier: 'ENTERPRISE',
        rateLimit: 5000,
      });

      expect(res.apiKey).toMatch(/^tg_live_/);
      expect(res.clientName).toBe('Unilever Philippines');
      expect(mockDb.b2bApiKey.create).toHaveBeenCalled();
    });
  });

  describe('getBrandVelocity', () => {
    it('should aggregate sales items into brand velocity feed', async () => {
      mockDb.sale.findMany.mockResolvedValue([
        {
          items: [
            { name: 'Bear Brand Fortified 33g', category: 'Dairy', quantity: 10, price: 15 },
            { name: 'Nescafe Classic 2g', category: 'Coffee', quantity: 20, price: 5 },
          ],
          totalAmount: 250,
          createdAt: new Date(),
        },
        {
          items: [
            { name: 'Nescafe Classic 2g', category: 'Coffee', quantity: 15, price: 5 },
          ],
          totalAmount: 75,
          createdAt: new Date(),
        },
      ]);

      const res = await controller.getBrandVelocity({ limit: 10 });
      expect(res.topVelocityProducts.length).toBe(2);
      expect(res.topVelocityProducts[0].productName).toBe('Nescafe Classic 2g');
      expect(res.topVelocityProducts[0].unitsSold).toBe(35);
      expect(res.topVelocityProducts[0].totalVolumePhp).toBe(175);
    });
  });

  describe('getPricingBenchmarks', () => {
    it('should calculate min, max, avg, and median street prices', async () => {
      mockDb.product.findMany.mockResolvedValue([
        {
          barcode: '4800016644802',
          name: 'Lucky Me Pancit Canton',
          category: 'Noodles',
          sellingPrice: 15,
          costPrice: 12,
          isTingi: false,
        },
        {
          barcode: '4800016644802',
          name: 'Lucky Me Pancit Canton',
          category: 'Noodles',
          sellingPrice: 16,
          costPrice: 13,
          isTingi: false,
        },
        {
          barcode: '4800016644802',
          name: 'Lucky Me Pancit Canton',
          category: 'Noodles',
          sellingPrice: 17,
          costPrice: 13,
          isTingi: false,
        },
      ]);

      const res = await controller.getPricingBenchmarks({
        barcode: '4800016644802',
      });
      expect(res.benchmarks.length).toBe(1);
      const b = res.benchmarks[0];
      expect(b.minPrice).toBe(15);
      expect(b.maxPrice).toBe(17);
      expect(b.avgPrice).toBe(16);
      expect(b.medianPrice).toBe(16);
      expect(b.sampleCount).toBe(3);
    });
  });

  describe('getTingiRatio', () => {
    it('should calculate tingi packaging adoption percentage', async () => {
      mockDb.product.count
        .mockResolvedValueOnce(100) // total
        .mockResolvedValueOnce(45); // tingi

      const res = await controller.getTingiRatio();
      expect(res.totalCatalogedProducts).toBe(100);
      expect(res.tingiProductsCount).toBe(45);
      expect(res.tingiRatioPercentage).toBe(45);
      expect(res.insight).toContain('High micro-transaction portioning');
    });
  });
});
