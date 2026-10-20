import { Controller, Get } from '@nestjs/common';
import { StorefrontServiceService } from './storefront-service.service.js';

@Controller()
export class StorefrontServiceController {
  constructor(private readonly storefrontServiceService: StorefrontServiceService) {}

  @Get()
  getHello(): string {
    return this.storefrontServiceService.getHello();
  }
}
