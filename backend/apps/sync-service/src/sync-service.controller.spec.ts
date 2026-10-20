import { Test, TestingModule } from '@nestjs/testing';
import { SyncServiceController } from './sync-service.controller.js';
import { SyncServiceService } from './sync-service.service.js';
import { DatabaseService } from '../../../libs/database/src/database.service.js';
import { JwtService } from '@nestjs/jwt';

describe('SyncServiceController', () => {
  let syncServiceController: SyncServiceController;

  beforeEach(async () => {
    const mockDb = {
      product: { findUnique: vi.fn(), update: vi.fn(), create: vi.fn(), findMany: vi.fn() },
      sale: { findFirst: vi.fn(), create: vi.fn(), findMany: vi.fn() },
      debt: { findFirst: vi.fn(), update: vi.fn(), create: vi.fn(), findMany: vi.fn() },
      gcashLedger: { findFirst: vi.fn(), create: vi.fn(), findMany: vi.fn() },
      store: { findFirst: vi.fn().mockResolvedValue({ id: 'store-1', name: 'My Store', slug: 'my-store' }) },
    };

    const mockJwt = {
      verifyAsync: vi.fn().mockResolvedValue({ sub: 'merchant-1' }),
    };

    const app: TestingModule = await Test.createTestingModule({
      controllers: [SyncServiceController],
      providers: [
        SyncServiceService,
        { provide: DatabaseService, useValue: mockDb },
        { provide: JwtService, useValue: mockJwt },
      ],
    }).compile();

    syncServiceController = app.get<SyncServiceController>(SyncServiceController);
  });

  describe('root', () => {
    it('should return service info', () => {
      const info = syncServiceController.getInfo();
      expect(info.service).toBe('sync-service');
      expect(info.status).toBe('online');
    });

    it('should return health ok', () => {
      const health = syncServiceController.getHealth();
      expect(health.status).toBe('ok');
    });

    it('should manage companion scanner lifecycle (session -> push scan -> poll)', async () => {
      // 1. Create session
      const session = await syncServiceController.createCompanionSession();
      expect(session.success).toBe(true);
      expect(session.sessionId).toBeDefined();
      expect(session.pairingCode).toMatch(/^SCAN-\d{4}$/);

      // 2. Push scan from phone
      const scan = await syncServiceController.pushCompanionScan({
        sessionId: session.sessionId,
        barcode: '4800016644819',
      });
      expect(scan.success).toBe(true);
      expect(scan.barcode).toBe('4800016644819');

      // 3. Poll scans on Web POS
      const poll = await syncServiceController.pollCompanionScans(session.sessionId);
      expect(poll.success).toBe(true);
      expect(poll.newScans.length).toBe(1);
      expect(poll.newScans[0].barcode).toBe('4800016644819');
    });
  });
});
