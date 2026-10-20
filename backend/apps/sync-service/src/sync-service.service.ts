import { Injectable } from '@nestjs/common';

@Injectable()
export class SyncServiceService {
  getHello(): string {
    return 'Hello World!';
  }
}
