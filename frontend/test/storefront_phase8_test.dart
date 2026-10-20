import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tindagrid/features/storefront/storefront_service.dart';
import 'package:tindagrid/features/storefront/storefront_provider.dart';

void main() {
  group('Phase 8: Storefront Discovery & Cloudflare Pages Tests', () {
    test('8.1 Byte Compression reduces oversized raw images to target limit', () {
      final service = StorefrontService();
      // Generate 500 KB dummy payload
      final largeBytes = Uint8List(500 * 1024);
      final compressed = service.compressBytes(largeBytes, maxBytes: 200 * 1024);

      expect(compressed.lengthInBytes, lessThanOrEqualTo(200 * 1024));
    });

    test('8.1 Direct S3/R2 Upload requests presigned URL and sends PUT payload', () async {
      late Uri capturedPutUri;
      late String capturedContentType;

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.contains('upload-url')) {
          return http.Response(
            jsonEncode({
              'uploadUrl': 'https://r2.cloudflare.com/mock-upload',
              'publicUrl': 'https://cdn.tindagrid.com/storefronts/store-1/cover.webp',
              'fileKey': 'storefronts/store-1/cover.webp',
            }),
            200,
          );
        } else if (request.method == 'PUT') {
          capturedPutUri = request.url;
          capturedContentType = request.headers['Content-Type'] ?? '';
          return http.Response('', 200);
        } else if (request.method == 'PATCH') {
          return http.Response(
            jsonEncode({
              'store': {
                'id': 'store-1',
                'name': 'Tindahan ni Juan',
                'slug': 'tindahan-ni-juan',
                'photoUrl': 'https://cdn.tindagrid.com/storefronts/store-1/cover.webp',
                'isPublic': true,
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = StorefrontService(client: mockClient);
      final dummyBytes = Uint8List(50 * 1024); // 50 KB
      final publicUrl = await service.uploadStorefrontPhoto(
        storeId: 'store-1',
        photoBytes: dummyBytes,
      );

      expect(publicUrl, 'https://cdn.tindagrid.com/storefronts/store-1/cover.webp');
      expect(capturedPutUri.toString(), 'https://r2.cloudflare.com/mock-upload');
      expect(capturedContentType, 'image/webp');
    });

    test('8.2 Draft vs Public Storefront Toggle updates visibility state', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'store': {
              'id': 'demo-store-id',
              'name': "Aling Nena's Sari-Sari Store",
              'slug': 'aling-nena',
              'isPublic': true,
            }
          }),
          200,
        );
      });

      final container = ProviderContainer(
        overrides: [
          storefrontServiceProvider.overrideWithValue(StorefrontService(client: mockClient)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(storefrontProvider.notifier);
      expect(container.read(storefrontProvider).isPublic, false);

      final success = await notifier.setPublicVisibility(true);
      expect(success, true);
      expect(container.read(storefrontProvider).isPublic, true);
    });

    test('8.2 Store Profile details update and slug sanitization', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'store': {
              'id': 'demo-store-id',
              'name': 'Mang Tomas Store',
              'slug': 'mang-tomas-store',
              'address': 'Brgy Holy Spirit, QC',
              'isPublic': false,
            }
          }),
          200,
        );
      });

      final container = ProviderContainer(
        overrides: [
          storefrontServiceProvider.overrideWithValue(StorefrontService(client: mockClient)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(storefrontProvider.notifier);
      await notifier.updateDetails(
        name: 'Mang Tomas Store',
        slug: 'Mang Tomas @ Store!',
        address: 'Brgy Holy Spirit, QC',
      );

      final state = container.read(storefrontProvider);
      expect(state.name, 'Mang Tomas Store');
      expect(state.slug, 'mang-tomas---store-');
      expect(state.address, 'Brgy Holy Spirit, QC');
      expect(state.publicUrl, 'https://tindagrid.com/mang-tomas---store-');
    });

    test('8.2 GPS coordinate lock updates latitude and longitude', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'store': {'id': 'demo-store-id'}}), 200);
      });

      final container = ProviderContainer(
        overrides: [
          storefrontServiceProvider.overrideWithValue(StorefrontService(client: mockClient)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(storefrontProvider.notifier);
      await notifier.updateGpsCoordinates(14.6507, 121.0494);

      final state = container.read(storefrontProvider);
      expect(state.latitude, 14.6507);
      expect(state.longitude, 121.0494);
    });
  });
}
