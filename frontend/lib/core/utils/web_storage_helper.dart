import 'web_storage_stub.dart'
    if (dart.library.js_interop) 'web_storage_web.dart';

class WebStorageHelper {
  WebStorageHelper._();

  /// Requests permanent storage persistence to prevent browser cache eviction
  static Future<void> requestPersistentStorage() => requestPersistentStorageImpl();
}
