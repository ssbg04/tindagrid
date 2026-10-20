import 'package:flutter/services.dart';

typedef BarcodeScanCallback = void Function(String barcode);

/// Hardware Keyboard Barcode Scanner Listener
/// Captures rapid keystrokes emitted by USB/Bluetooth barcode scanner guns
class BarcodeKeyboardListener {
  final BarcodeScanCallback onBarcodeScanned;
  final int maxInterKeyDelayMs;
  final int minBarcodeLength;

  final StringBuffer _buffer = StringBuffer();
  DateTime _lastKeystrokeTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool _isListening = false;

  BarcodeKeyboardListener({
    required this.onBarcodeScanned,
    this.maxInterKeyDelayMs = 250,
    this.minBarcodeLength = 3,
  });

  /// Start listening for hardware scanner key events
  void start() {
    if (_isListening) return;
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _isListening = true;
  }

  /// Stop listening
  void stop() {
    if (!_isListening) return;
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _buffer.clear();
    _isListening = false;
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    final now = DateTime.now();
    final delay = now.difference(_lastKeystrokeTime).inMilliseconds;
    _lastKeystrokeTime = now;

    // If typing was too slow, reset buffer (it was human typing, not a scanner gun)
    if (_buffer.isNotEmpty && delay > maxInterKeyDelayMs) {
      _buffer.clear();
    }

    // Check for scanner termination (Enter / Numpad Enter)
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final code = _buffer.toString().trim();
      _buffer.clear();

      if (code.length >= minBarcodeLength) {
        onBarcodeScanned(code);
        return true;
      }
      return false;
    }

    // Capture printable characters (numbers, letters, dashes)
    final char = event.character;
    if (char != null && char.isNotEmpty && char.codeUnitAt(0) >= 32 && char.codeUnitAt(0) <= 126) {
      _buffer.write(char);
    }

    return false;
  }
}
