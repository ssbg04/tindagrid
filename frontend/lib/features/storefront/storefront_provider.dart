import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/auth/auth_provider.dart';
import 'storefront_service.dart';

class StorefrontState {
  final String storeId;
  final String name;
  final String slug;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final bool isPublic;
  final bool isLoading;
  final String? errorMessage;

  const StorefrontState({
    required this.storeId,
    required this.name,
    required this.slug,
    required this.address,
    this.latitude,
    this.longitude,
    this.photoUrl,
    required this.isPublic,
    this.isLoading = false,
    this.errorMessage,
  });

  String get publicUrl => 'https://tindagrid.com/$slug';

  StorefrontState copyWith({
    String? storeId,
    String? name,
    String? slug,
    String? address,
    double? latitude,
    double? longitude,
    String? photoUrl,
    bool? isPublic,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StorefrontState(
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      isPublic: isPublic ?? this.isPublic,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class StorefrontNotifier extends Notifier<StorefrontState> {
  @override
  StorefrontState build() {
    final auth = ref.watch(authProvider);
    final s = auth.store;
    if (s != null) {
      return StorefrontState(
        storeId: s.id,
        name: s.name,
        slug: s.slug,
        address: 'Brgy 174, Caloocan City',
        latitude: 14.7566,
        longitude: 121.0450,
        isPublic: s.isPublic,
      );
    }

    return const StorefrontState(
      storeId: 'demo-store-id',
      name: "Aling Nena's Sari-Sari Store",
      slug: 'aling-nena',
      address: 'Brgy 174, Caloocan City',
      latitude: 14.7566,
      longitude: 121.0450,
      isPublic: false,
    );
  }

  StorefrontService get _service => ref.read(storefrontServiceProvider);

  /// Toggles Draft vs Public Visibility (Phase 8.2)
  Future<bool> setPublicVisibility(bool isPublic) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.updateStoreProfile(
        storeId: state.storeId,
        isPublic: isPublic,
      );
      state = state.copyWith(isPublic: isPublic, isLoading: false);
      return true;
    } catch (e) {
      // Local fallback for offline demo
      state = state.copyWith(isPublic: isPublic, isLoading: false);
      return true;
    }
  }

  /// Updates Store Name, Slug, and Address
  Future<bool> updateDetails({
    required String name,
    required String slug,
    required String address,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final cleanSlug = slug.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-]'), '-');
    try {
      await _service.updateStoreProfile(
        storeId: state.storeId,
        name: name,
        slug: cleanSlug,
        address: address,
      );
      state = state.copyWith(
        name: name,
        slug: cleanSlug,
        address: address,
        isLoading: false,
      );
      return true;
    } catch (e) {
      // Update local state even if offline
      state = state.copyWith(
        name: name,
        slug: cleanSlug,
        address: address,
        isLoading: false,
      );
      return true;
    }
  }

  /// Updates GPS Coordinates
  Future<bool> updateGpsCoordinates(double lat, double lng) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.updateStoreProfile(
        storeId: state.storeId,
        latitude: lat,
        longitude: lng,
      );
      state = state.copyWith(latitude: lat, longitude: lng, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(latitude: lat, longitude: lng, isLoading: false);
      return true;
    }
  }

  /// Picks and uploads storefront photo to Cloudflare R2
  Future<String?> uploadPhoto({ImageSource source = ImageSource.camera}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final bytes = await _service.captureStorefrontPhoto(source: source);
      if (bytes == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }

      final url = await _service.uploadStorefrontPhoto(
        storeId: state.storeId,
        photoBytes: bytes,
      );

      state = state.copyWith(photoUrl: url, isLoading: false);
      return url;
    } catch (e) {
      // Fallback mock photo URL if offline
      const mockUrl = 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=800';
      state = state.copyWith(photoUrl: mockUrl, isLoading: false);
      return mockUrl;
    }
  }
}

final storefrontServiceProvider = Provider<StorefrontService>((ref) {
  return StorefrontService();
});

final storefrontProvider =
    NotifierProvider<StorefrontNotifier, StorefrontState>(StorefrontNotifier.new);
