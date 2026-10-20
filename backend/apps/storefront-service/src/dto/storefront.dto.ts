export class UpdateStorefrontDto {
  name?: string;
  slug?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  photoUrl?: string;
  isPublic?: boolean;
}

export class NearbyQueryDto {
  lat!: number;
  lng!: number;
  radiusMeters?: number;
  limit?: number;
}
