import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import '../constants/api_constants.dart';
import 'auth_models.dart';

class AuthService {
  final http.Client _client;
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;
  final String baseUrl;

  AuthService({
    http.Client? client,
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication(),
        baseUrl = baseUrl ?? ApiConstants.defaultBaseUrl;

  static const _keyAccessToken = 'tg_access_token';
  static const _keyRefreshToken = 'tg_refresh_token';
  static const _keyMerchant = 'tg_merchant_user';
  static const _keyStore = 'tg_store_info';

  /// Register a new merchant with Phone and 4-6 digit Store PIN
  Future<AuthState> register({
    required String phone,
    required String fullName,
    required String pin,
    String? securityQuestion,
    String? securityAnswer,
    String? storeName,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'fullName': fullName,
        'pin': pin,
        'securityQuestion': ?securityQuestion,
        'securityAnswer': ?securityAnswer,
        'storeName': ?storeName,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final user = MerchantUser.fromJson(data['merchant'] as Map<String, dynamic>);
      final store = StoreInfo.fromJson(data['store'] as Map<String, dynamic>);
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      await _persistSession(accessToken, refreshToken, user, store);

      return AuthState(
        isAuthenticated: true,
        user: user,
        store: store,
        accessToken: accessToken,
      );
    } else {
      throw Exception(data['message'] ?? 'Nabigo ang pagpaparehistro');
    }
  }

  /// Login with Phone and Store PIN
  Future<AuthState> login({
    required String phone,
    required String pin,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'pin': pin,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final user = MerchantUser.fromJson(data['merchant'] as Map<String, dynamic>);
      final storesList = data['stores'] as List<dynamic>;
      final store = storesList.isNotEmpty
          ? StoreInfo.fromJson(storesList.first as Map<String, dynamic>)
          : null;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      await _persistSession(accessToken, refreshToken, user, store);

      return AuthState(
        isAuthenticated: true,
        user: user,
        store: store,
        accessToken: accessToken,
      );
    } else {
      throw Exception(data['message'] ?? 'Maling numero o Store PIN');
    }
  }

  /// Recover forgotten PIN using secret Security Question & Answer
  Future<bool> recoverPin({
    required String phone,
    required String securityQuestion,
    required String securityAnswer,
    required String newPin,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/recover-pin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'securityQuestion': securityQuestion,
        'securityAnswer': securityAnswer,
        'newPin': newPin,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data['success'] as bool? ?? true;
    } else {
      throw Exception(data['message'] ?? 'Nabigo ang pagbawi ng Store PIN');
    }
  }

  /// Authenticate device owner using native biometrics (Fingerprint / Face ID)
  Future<bool> authenticateWithBiometrics({String reason = 'I-verify ang iyong fingerprint para sa Tindahan PIN'}) async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();

      if (!canCheck && !isSupported) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // Allows lock screen pattern/PIN fallback
      );
    } catch (_) {
      return false;
    }
  }

  /// Silently refresh the 30-day access token in background
  Future<String?> refreshAccessToken() async {
    final refreshToken = await _storage.read(key: _keyRefreshToken);
    if (refreshToken == null) return null;

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;

        await _storage.write(key: _keyAccessToken, value: newAccessToken);
        await _storage.write(key: _keyRefreshToken, value: newRefreshToken);

        return newAccessToken;
      }
    } catch (_) {}
    return null;
  }

  /// Load session from encrypted device storage on app launch
  Future<AuthState> loadPersistedSession() async {
    try {
      final accessToken = await _storage.read(key: _keyAccessToken);
      final userJson = await _storage.read(key: _keyMerchant);
      final storeJson = await _storage.read(key: _keyStore);

      if (accessToken != null && userJson != null) {
        final user = MerchantUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        final store = storeJson != null
            ? StoreInfo.fromJson(jsonDecode(storeJson) as Map<String, dynamic>)
            : null;

        return AuthState(
          isAuthenticated: true,
          user: user,
          store: store,
          accessToken: accessToken,
        );
      }
    } catch (_) {}

    return const AuthState(isAuthenticated: false);
  }

  /// Logout and clear secure device storage
  Future<void> logout() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyMerchant);
    await _storage.delete(key: _keyStore);
  }

  Future<void> _persistSession(
    String accessToken,
    String refreshToken,
    MerchantUser user,
    StoreInfo? store,
  ) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyMerchant, value: jsonEncode(user.toJson()));
    if (store != null) {
      await _storage.write(key: _keyStore, value: jsonEncode(store.toJson()));
    }
  }
}
