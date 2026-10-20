import { Test, TestingModule } from '@nestjs/testing';
import { B2bAnalyticsServiceController } from './b2b-analytics-service.controller.js';
import { B2bAnalyticsServiceService } from './b2b-analytics-service.service.js';

describe('B2bAnalyticsServiceController', () => {
  let b2bAnalyticsServiceController: B2bAnalyticsServiceController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [B2bAnalyticsServiceController],
      providers: [B2bAnalyticsServiceService],
    }).compile();

    b2bAnalyticsServiceController = app.get<B2bAnalyticsServiceController>(B2bAnalyticsServiceController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(b2bAnalyticsServiceController.getHello()).toBe('Hello World!');
    });
  });
});
