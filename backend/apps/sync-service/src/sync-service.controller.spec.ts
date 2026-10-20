import { Test, TestingModule } from '@nestjs/testing';
import { SyncServiceController } from './sync-service.controller.js';
import { SyncServiceService } from './sync-service.service.js';

describe('SyncServiceController', () => {
  let syncServiceController: SyncServiceController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [SyncServiceController],
      providers: [SyncServiceService],
    }).compile();

    syncServiceController = app.get<SyncServiceController>(SyncServiceController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(syncServiceController.getHello()).toBe('Hello World!');
    });
  });
});
