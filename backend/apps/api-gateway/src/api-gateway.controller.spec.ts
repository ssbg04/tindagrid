import { Test, TestingModule } from '@nestjs/testing';
import { ApiGatewayController } from './api-gateway.controller.js';
import { ApiGatewayService } from './api-gateway.service.js';
import { DatabaseService } from '../../../libs/database/src/database.service.js';

describe('ApiGatewayController', () => {
  let apiGatewayController: ApiGatewayController;

  beforeEach(async () => {
    const mockDb = {
      $queryRaw: vi.fn().mockResolvedValue([{ 1: 1 }]),
    };

    const app: TestingModule = await Test.createTestingModule({
      controllers: [ApiGatewayController],
      providers: [
        ApiGatewayService,
        { provide: DatabaseService, useValue: mockDb },
      ],
    }).compile();

    apiGatewayController = app.get<ApiGatewayController>(ApiGatewayController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(apiGatewayController.getHello()).toBe('Hello World!');
    });

    it('should return health status', async () => {
      const health = await apiGatewayController.getHealth();
      expect(health.status).toBe('ok');
      expect(health.service).toBe('api-gateway');
    });
  });
});
