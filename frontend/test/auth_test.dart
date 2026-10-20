import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tindagrid/core/auth/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // In-memory mock storage for tests
  FlutterSecureStorage.setMockInitialValues({});

  group('AuthService Tests', () {
    test('Successful registration parses merchant, store, and persists tokens', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/register') {
          return http.Response(
            jsonEncode({
              'message': 'Matagumpay na narehistro ang tindahan!',
              'merchant': {
                'id': 'm-123',
                'phone': '+639171234567',
                'fullName': 'Aling Nena',
                'role': 'MERCHANT',
                'hasSecurityQuestion': true,
              },
              'store': {
                'id': 's-456',
                'name': 'Aling Nena Store',
                'slug': 'aling-nena-store',
                'isPublic': false,
              },
              'accessToken': 'mock-access-token',
              'refreshToken': 'mock-refresh-token',
              'expiresIn': '30d',
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(
        client: mockClient,
        storage: const FlutterSecureStorage(),
        baseUrl: 'http://localhost:3000',
      );

      final state = await authService.register(
        phone: '09171234567',
        fullName: 'Aling Nena',
        pin: '1234',
        securityQuestion: 'PET_NAME',
        securityAnswer: 'Bantay',
        storeName: 'Aling Nena Store',
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.user?.fullName, 'Aling Nena');
      expect(state.store?.slug, 'aling-nena-store');
      expect(state.accessToken, 'mock-access-token');

      // Verify persisted session can be loaded back
      final loadedSession = await authService.loadPersistedSession();
      expect(loadedSession.isAuthenticated, isTrue);
      expect(loadedSession.user?.phone, '+639171234567');
      expect(loadedSession.store?.name, 'Aling Nena Store');
    });

    test('Successful login restores merchant session', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/login') {
          return http.Response(
            jsonEncode({
              'message': 'Maligayang pagbabalik!',
              'merchant': {
                'id': 'm-789',
                'phone': '+639189998877',
                'fullName': 'Mang Kanor',
                'role': 'MERCHANT',
                'hasSecurityQuestion': false,
              },
              'stores': [
                {
                  'id': 's-789',
                  'name': 'Mang Kanor Sari-Sari',
                  'slug': 'mang-kanor-sari-sari',
                  'isPublic': true,
                }
              ],
              'accessToken': 'login-access-token',
              'refreshToken': 'login-refresh-token',
              'expiresIn': '30d',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(
        client: mockClient,
        storage: const FlutterSecureStorage(),
        baseUrl: 'http://localhost:3000',
      );

      final state = await authService.login(
        phone: '09189998877',
        pin: '2580',
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.user?.fullName, 'Mang Kanor');
      expect(state.store?.name, 'Mang Kanor Sari-Sari');
      expect(state.accessToken, 'login-access-token');
    });

    test('PIN recovery returns true when question and answer are verified', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/recover-pin') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Matagumpay na nabago ang iyong Store PIN!',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(
        client: mockClient,
        baseUrl: 'http://localhost:3000',
      );

      final success = await authService.recoverPin(
        phone: '09171234567',
        securityQuestion: 'PET_NAME',
        securityAnswer: 'Bantay',
        newPin: '9999',
      );

      expect(success, isTrue);
    });
  });
}
