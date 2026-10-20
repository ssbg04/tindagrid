import { Test, TestingModule } from '@nestjs/testing';
import { StorefrontServiceController } from './storefront-service.controller.js';
import { StorefrontServiceService } from './storefront-service.service.js';

describe('StorefrontServiceController', () => {
  let storefrontServiceController: StorefrontServiceController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [StorefrontServiceController],
      providers: [StorefrontServiceService],
    }).compile();

    storefrontServiceController = app.get<StorefrontServiceController>(StorefrontServiceController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(storefrontServiceController.getHello()).toBe('Hello World!');
    });
  });
});
