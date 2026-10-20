import { Test, TestingModule } from '@nestjs/testing';
import { StorefrontServiceController } from './storefront-service.controller.js';
import { StorefrontServiceService } from './storefront-service.service.js';
import { DatabaseService } from '../../../libs/database/src/database.service.js';
import { R2StorageService } from '../../../libs/common/src/storage/r2-storage.service.js';

describe('StorefrontServiceController', () => {
  let controller: StorefrontServiceController;
  let service: StorefrontServiceService;

  const mockDb = {
    store: {
      findUnique: vi.fn(),
      findMany: vi.fn(),
      update: vi.fn(),
    },
    product: {
      findMany: vi.fn(),
    },
    $queryRawUnsafe: vi.fn(),
  };

  const mockR2 = {
    getPresignedUploadUrl: vi.fn().mockResolvedValue({
      uploadUrl: 'https://upload.r2.test',
      publicUrl: 'https://cdn.tindagrid.com/test.webp',
      fileKey: 'test.webp',
    }),
  };

  beforeEach(async () => {
    vi.clearAllMocks();
    const app: TestingModule = await Test.createTestingModule({
      controllers: [StorefrontServiceController],
      providers: [
        StorefrontServiceService,
        { provide: DatabaseService, useValue: mockDb },
        { provide: R2StorageService, useValue: mockR2 },
      ],
    }).compile();

    controller = app.get<StorefrontServiceController>(StorefrontServiceController);
    service = app.get<StorefrontServiceService>(StorefrontServiceService);
  });

  describe('root & health', () => {
    it('should return service info', () => {
      const info = controller.getInfo();
      expect(info.service).toBe('storefront-service');
      expect(info.status).toBe('online');
    });

    it('should return health status', () => {
      const health = controller.getHealth();
      expect(health.status).toBe('ok');
    });
  });

  describe('getStoreBySlug', () => {
    it('should return store metadata if store is public', async () => {
      mockDb.store.findUnique.mockResolvedValue({
        id: 'store-123',
        name: "Aling Nena's Sari-Sari Store",
        slug: 'aling-nena',
        address: 'Brgy 174, Caloocan',
        latitude: 14.7566,
        longitude: 121.045,
        photoUrl: 'https://cdn.tindagrid.com/aling-nena.webp',
        isPublic: true,
        merchant: { fullName: 'Nena Santos', phone: '09171234567' },
        createdAt: new Date(),
      });

      const res = await controller.getStoreBySlug('aling-nena');
      expect(res.name).toBe("Aling Nena's Sari-Sari Store");
      expect(res.merchantName).toBe('Nena Santos');
      expect(res.isPublic).toBe(true);
    });

    it('should throw NotFoundException if store is private or not found', async () => {
      mockDb.store.findUnique.mockResolvedValue(null);
      await expect(controller.getStoreBySlug('unknown')).rejects.toThrow();
    });
  });

  describe('getStoreProducts', () => {
    it('should return active products for public store', async () => {
      mockDb.store.findUnique.mockResolvedValue({ id: 'store-123', isPublic: true });
      mockDb.product.findMany.mockResolvedValue([
        {
          id: 'prod-1',
          barcode: '4800016644802',
          name: 'Lucky Me Pancit Canton Original',
          sellingPrice: 15,
          currentStock: 25,
          isTingi: false,
        },
      ]);

      const res = await controller.getStoreProducts('aling-nena');
      expect(res.totalItems).toBe(1);
      expect(res.products[0].name).toBe('Lucky Me Pancit Canton Original');
    });
  });

  describe('findNearby', () => {
    it('should return stores within radius', async () => {
      mockDb.$queryRawUnsafe.mockResolvedValue([
        {
          id: 'store-1',
          name: "Aling Nena's Sari-Sari Store",
          slug: 'aling-nena',
          address: 'Brgy 174, Caloocan',
          latitude: 14.7566,
          longitude: 121.045,
          photoUrl: null,
          isPublic: true,
          distanceMeters: 450.5,
        },
      ]);

      const stores = await controller.findNearby('14.756', '121.045', '2000', '10');
      expect(stores.length).toBe(1);
      expect(stores[0].slug).toBe('aling-nena');
      expect(stores[0].distanceMeters).toBe(450.5);
    });
  });

  describe('getPhotoUploadUrl', () => {
    it('should return presigned R2 upload URL', async () => {
      mockDb.store.findUnique.mockResolvedValue({ id: 'store-123' });
      const res = await controller.getPhotoUploadUrl('store-123', 'image/webp');
      expect(res.uploadUrl).toBe('https://upload.r2.test');
      expect(res.publicUrl).toBe('https://cdn.tindagrid.com/test.webp');
    });
  });
});
