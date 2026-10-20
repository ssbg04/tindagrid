import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class R2StorageService {
  private readonly logger = new Logger(R2StorageService.name);
  private readonly s3Client: S3Client | null = null;
  private readonly bucketName: string;
  private readonly publicBaseUrl: string;

  constructor(private readonly configService: ConfigService) {
    const accountId = this.configService.get<string>('CLOUDFLARE_R2_ACCOUNT_ID');
    const accessKeyId = this.configService.get<string>('CLOUDFLARE_R2_ACCESS_KEY_ID');
    const secretAccessKey = this.configService.get<string>('CLOUDFLARE_R2_SECRET_ACCESS_KEY');
    this.bucketName = this.configService.get<string>('CLOUDFLARE_R2_BUCKET_NAME') ?? 'tindagrid-storefronts';
    this.publicBaseUrl = this.configService.get<string>('CLOUDFLARE_R2_PUBLIC_URL') ?? '';

    if (accountId && accessKeyId && secretAccessKey) {
      this.s3Client = new S3Client({
        region: 'auto',
        endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
        credentials: {
          accessKeyId,
          secretAccessKey,
        },
      });
      this.logger.log('Cloudflare R2 Storage client initialized successfully.');
    } else {
      this.logger.warn('Cloudflare R2 credentials missing. Direct S3 uploads will require credentials.');
    }
  }

  /**
   * Generates a pre-signed PUT URL allowing mobile/web clients to upload directly to R2
   * with zero server bandwidth/egress cost.
   */
  async getPresignedUploadUrl(
    fileKey: string,
    contentType: string = 'image/webp',
    expiresIn: number = 300,
  ): Promise<{ uploadUrl: string; publicUrl: string; fileKey: string }> {
    if (!this.s3Client) {
      throw new Error('Cloudflare R2 Storage is not configured with valid credentials.');
    }

    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: fileKey,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(this.s3Client, command, { expiresIn });
    const publicUrl = this.publicBaseUrl
      ? `${this.publicBaseUrl}/${fileKey}`
      : uploadUrl.split('?')[0];

    return {
      uploadUrl,
      publicUrl,
      fileKey,
    };
  }
}
