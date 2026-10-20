import { Injectable } from '@nestjs/common';

@Injectable()
export class StorefrontServiceService {
  getHello(): string {
    return 'Hello World!';
  }
}
