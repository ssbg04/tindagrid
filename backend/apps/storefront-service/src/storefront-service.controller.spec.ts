import { Test, TestingModule } from '@nestjs/testing';
import { StorefrontServiceController } from './storefront-service.controller.js';
import { StorefrontServiceService } from './storefront-service.service.js';

describe('StorefrontServiceController', () => {
  let controller: StorefrontServiceController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [StorefrontServiceController],
      providers: [StorefrontServiceService],
    }).compile();

    controller = app.get<StorefrontServiceController>(StorefrontServiceController);
  });

  describe('root', () => {
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
});
