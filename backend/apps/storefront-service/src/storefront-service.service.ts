import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { DatabaseService } from '@lib/database';
import { R2StorageService } from '@lib/common';
import { UpdateStorefrontDto } from './dto/storefront.dto.js';

export interface NearbyStoreResult {
  id: string;
  name: string;
  slug: string;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
  photoUrl: string | null;
  isPublic: boolean;
  distanceMeters: number;
}

@Injectable()
export class StorefrontServiceService {
  private readonly logger = new Logger(StorefrontServiceService.name);

  constructor(
    private readonly db: DatabaseService,
    private readonly r2Storage: R2StorageService,
  ) {}

  /**
   * Retrieves public storefront metadata by slug.
   */
  async getStoreBySlug(slug: string) {
    const store = await this.db.store.findUnique({
      where: { slug },
      include: {
        merchant: {
          select: {
            fullName: true,
            phone: true,
          },
        },
      },
    });

    if (!store || !store.isPublic) {
      throw new NotFoundException(`Store '${slug}' not found or is currently private.`);
    }

    return {
      id: store.id,
      name: store.name,
      slug: store.slug,
      address: store.address,
      latitude: store.latitude,
      longitude: store.longitude,
      photoUrl: store.photoUrl,
      isPublic: store.isPublic,
      merchantName: store.merchant?.fullName ?? 'Sari-Sari Store Owner',
      contactPhone: store.merchant?.phone ?? null,
      createdAt: store.createdAt,
    };
  }

  /**
   * Retrieves active, in-stock products for public customer browsing.
   */
  async getStoreProducts(slug: string) {
    const store = await this.db.store.findUnique({
      where: { slug },
      select: { id: true, isPublic: true },
    });

    if (!store || !store.isPublic) {
      throw new NotFoundException(`Store '${slug}' not found or is private.`);
    }

    const products = await this.db.product.findMany({
      where: {
        storeId: store.id,
        isDeleted: false,
        currentStock: { gt: 0 },
      },
      select: {
        id: true,
        barcode: true,
        name: true,
        category: true,
        sellingPrice: true,
        currentStock: true,
        unit: true,
        isTingi: true,
        imageUrl: true,
      },
      orderBy: { name: 'asc' },
    });

    return {
      storeSlug: slug,
      totalItems: products.length,
      products,
    };
  }

  /**
   * PostGIS Spatial Query: Finds public stores within a radius in meters.
   * Uses ST_DWithin and ST_Distance with ST_SetSRID(ST_MakePoint(lng, lat), 4326).
   */
  async findNearbyStores(
    lat: number,
    lng: number,
    radiusMeters: number = 5000,
    limit: number = 20,
  ): Promise<NearbyStoreResult[]> {
    if (isNaN(lat) || isNaN(lng)) {
      throw new BadRequestException('Valid latitude and longitude coordinates are required.');
    }

    try {
      // Execute PostGIS query via raw SQL
      const query = `
        SELECT 
          id, name, slug, address, latitude, longitude, "photoUrl", "isPublic",
          ROUND(ST_Distance(
            ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
            ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
          )::numeric, 1) as "distanceMeters"
        FROM stores
        WHERE "isPublic" = true
          AND latitude IS NOT NULL
          AND longitude IS NOT NULL
          AND ST_DWithin(
            ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
            ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
            $3
          )
        ORDER BY "distanceMeters" ASC
        LIMIT $4;
      `;

      const rows: any[] = await this.db.$queryRawUnsafe(
        query,
        lng,
        lat,
        radiusMeters,
        limit,
      );

      return rows.map((r) => ({
        id: r.id,
        name: r.name,
        slug: r.slug,
        address: r.address,
        latitude: r.latitude ? Number(r.latitude) : null,
        longitude: r.longitude ? Number(r.longitude) : null,
        photoUrl: r.photoUrl,
        isPublic: Boolean(r.isPublic),
        distanceMeters: Number(r.distanceMeters || 0),
      }));
    } catch (err: any) {
      this.logger.warn(
        `PostGIS query failed (${err.message}). Falling back to in-memory Haversine distance.`,
      );

      // Fallback Haversine query for environments without PostGIS installed (e.g. SQLite unit tests)
      const stores = await this.db.store.findMany({
        where: {
          isPublic: true,
          latitude: { not: null },
          longitude: { not: null },
        },
      });

      const results: NearbyStoreResult[] = [];
      for (const s of stores) {
        if (s.latitude == null || s.longitude == null) continue;
        const d = this.calculateHaversineDistance(
          lat,
          lng,
          s.latitude,
          s.longitude,
        );
        if (d <= radiusMeters) {
          results.push({
            id: s.id,
            name: s.name,
            slug: s.slug,
            address: s.address,
            latitude: s.latitude,
            longitude: s.longitude,
            photoUrl: s.photoUrl,
            isPublic: s.isPublic,
            distanceMeters: Math.round(d * 10) / 10,
          });
        }
      }

      results.sort((a, b) => a.distanceMeters - b.distanceMeters);
      return results.slice(0, limit);
    }
  }

  /**
   * Generates a pre-signed PUT upload URL for Cloudflare R2 bucket.
   */
  async getPhotoUploadUrl(storeId: string, contentType: string = 'image/webp') {
    const store = await this.db.store.findUnique({ where: { id: storeId } });
    if (!store) {
      throw new NotFoundException(`Store with ID '${storeId}' not found.`);
    }

    const fileKey = `storefronts/${storeId}/cover-${Date.now()}.webp`;

    try {
      const presigned = await this.r2Storage.getPresignedUploadUrl(
        fileKey,
        contentType,
        300,
      );
      return presigned;
    } catch (_err) {
      // Mock / fallback if R2 credentials are not set during local testing
      return {
        uploadUrl: `https://mock-r2.tindagrid.internal/${fileKey}`,
        publicUrl: `https://cdn.tindagrid.com/${fileKey}`,
        fileKey,
      };
    }
  }

  /**
   * Updates store profile, location coordinates, or public visibility toggle.
   */
  async updateStorefront(storeId: string, dto: UpdateStorefrontDto) {
    const store = await this.db.store.findUnique({ where: { id: storeId } });
    if (!store) {
      throw new NotFoundException(`Store with ID '${storeId}' not found.`);
    }

    // Validate coordinates if provided
    if (dto.latitude !== undefined && (dto.latitude < -90 || dto.latitude > 90)) {
      throw new BadRequestException('Latitude must be between -90 and 90.');
    }
    if (dto.longitude !== undefined && (dto.longitude < -180 || dto.longitude > 180)) {
      throw new BadRequestException('Longitude must be between -180 and 180.');
    }

    const updated = await this.db.store.update({
      where: { id: storeId },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.slug && { slug: dto.slug }),
        ...(dto.address !== undefined && { address: dto.address }),
        ...(dto.latitude !== undefined && { latitude: dto.latitude }),
        ...(dto.longitude !== undefined && { longitude: dto.longitude }),
        ...(dto.photoUrl !== undefined && { photoUrl: dto.photoUrl }),
        ...(dto.isPublic !== undefined && { isPublic: dto.isPublic }),
      },
    });

    return {
      message: 'Storefront updated successfully.',
      store: updated,
    };
  }

  private calculateHaversineDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const R = 6371e3; // Earth radius in meters
    const phi1 = (lat1 * Math.PI) / 180;
    const phi2 = (lat2 * Math.PI) / 180;
    const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
    const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

    const a =
      Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
      Math.cos(phi1) *
        Math.cos(phi2) *
        Math.sin(deltaLambda / 2) *
        Math.sin(deltaLambda / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }
}
