class MerchantUser {
  final String id;
  final String phone;
  final String fullName;
  final String role;
  final bool hasSecurityQuestion;

  const MerchantUser({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
    this.hasSecurityQuestion = false,
  });

  factory MerchantUser.fromJson(Map<String, dynamic> json) {
    return MerchantUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String? ?? 'MERCHANT',
      hasSecurityQuestion: json['hasSecurityQuestion'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'fullName': fullName,
        'role': role,
        'hasSecurityQuestion': hasSecurityQuestion,
      };
}

class StoreInfo {
  final String id;
  final String name;
  final String slug;
  final bool isPublic;

  const StoreInfo({
    required this.id,
    required this.name,
    required this.slug,
    this.isPublic = false,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      isPublic: json['isPublic'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'isPublic': isPublic,
      };
}

class AuthState {
  final bool isAuthenticated;
  final MerchantUser? user;
  final StoreInfo? store;
  final String? accessToken;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.store,
    this.accessToken,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    MerchantUser? user,
    StoreInfo? store,
    String? accessToken,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      store: store ?? this.store,
      accessToken: accessToken ?? this.accessToken,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
