import 'package:flutter/foundation.dart';

/// Centralized network endpoints and domain configurations for TindaGrid
class ApiConstants {
  /// Root domain for public frontstore and storefront URLs
  static const String rootDomain = 'tindagrid.us.ci';

  /// Production API Gateway endpoint
  static const String productionBaseUrl = 'https://api.tindagrid.us.ci';

  /// Local development fallback endpoint
  static const String localBaseUrl = 'http://localhost:3000';

  /// Returns the appropriate base URL based on runtime mode
  static String get defaultBaseUrl {
    if (kReleaseMode || kIsWeb) {
      return productionBaseUrl;
    }
    return localBaseUrl;
  }

  /// Frontstore web page base URL for a given store slug
  static String storefrontUrl(String slug) => 'https://$rootDomain/$slug';
}
