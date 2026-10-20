import { Test, TestingModule } from '@nestjs/testing';
import { B2bAnalyticsServiceController } from './b2b-analytics-service.controller.js';
import { B2bAnalyticsServiceService } from './b2b-analytics-service.service.js';

describe('B2bAnalyticsServiceController', () => {
  let controller: B2bAnalyticsServiceController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [B2bAnalyticsServiceController],
      providers: [B2bAnalyticsServiceService],
    }).compile();

    controller = app.get<B2bAnalyticsServiceController>(B2bAnalyticsServiceController);
  });

  describe('root', () => {
    it('should return service info', () => {
      const info = controller.getInfo();
      expect(info.service).toBe('b2b-analytics-service');
      expect(info.status).toBe('online');
    });

    it('should return health status', () => {
      const health = controller.getHealth();
      expect(health.status).toBe('ok');
    });
  });
});
