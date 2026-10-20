import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_models.dart';
import 'auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _loadSession();
    return const AuthState(isLoading: true);
  }

  AuthService get _authService => ref.read(authServiceProvider);

  Future<void> _loadSession() async {
    final session = await _authService.loadPersistedSession();
    state = session;
  }

  Future<void> register({
    required String phone,
    required String fullName,
    required String pin,
    String? securityQuestion,
    String? securityAnswer,
    String? storeName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newState = await _authService.register(
        phone: phone,
        fullName: fullName,
        pin: pin,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
        storeName: storeName,
      );
      state = newState;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> login({
    required String phone,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newState = await _authService.login(phone: phone, pin: pin);
      state = newState;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<bool> recoverPin({
    required String phone,
    required String securityQuestion,
    required String securityAnswer,
    required String newPin,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _authService.recoverPin(
        phone: phone,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
        newPin: newPin,
      );
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    return _authService.authenticateWithBiometrics();
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
