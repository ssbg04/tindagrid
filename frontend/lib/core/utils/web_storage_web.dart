import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

Future<void> requestPersistentStorageImpl() async {
  try {
    final storage = web.window.navigator.storage;
    final isPersisted = await storage.persist().toDart;
    debugPrint('[TindaGrid Web PWA] Storage persistence granted: $isPersisted');
  } catch (e) {
    debugPrint('[TindaGrid Web PWA] Storage persistence error: $e');
  }
}
