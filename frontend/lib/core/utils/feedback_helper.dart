import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class FeedbackHelper {
  static final AudioPlayer _player = AudioPlayer();
  static Uint8List? _cachedSuccessBeep;
  static Uint8List? _cachedErrorBuzz;

  /// Generate a valid mono PCM WAV in memory
  static Uint8List _generateWav({
    required double frequency,
    required double durationSeconds,
    int sampleRate = 16000,
    bool isDoubleBuzz = false,
  }) {
    final totalSamples = (sampleRate * durationSeconds).toInt();
    final byteRate = sampleRate * 2; // 16-bit mono
    final dataSize = totalSamples * 2;
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);

    // RIFF header
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint8(8, 0x57);  // 'W'
    buffer.setUint8(9, 0x41);  // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // subchunk1Size (16 for PCM)
    buffer.setUint16(20, 1, Endian.little);  // audioFormat (1 for PCM)
    buffer.setUint16(22, 1, Endian.little);  // numChannels (1 for mono)
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, 2, Endian.little);  // blockAlign
    buffer.setUint16(34, 16, Endian.little); // bitsPerSample

    // data subchunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);

    // Audio samples
    int offset = 44;
    for (int i = 0; i < totalSamples; i++) {
      double t = i / sampleRate;
      double sample = 0;

      if (!isDoubleBuzz) {
        // High crisp scanner beep (sine wave with soft attack & decay)
        final envelope = sin(pi * (i / totalSamples));
        sample = sin(2 * pi * frequency * t) * envelope;
      } else {
        // Low double buzz (square-ish wave interrupted in the middle)
        final pulsePhase = (t / durationSeconds);
        final isSilentGap = (pulsePhase > 0.4 && pulsePhase < 0.6);
        if (!isSilentGap) {
          sample = sin(2 * pi * frequency * t) > 0 ? 0.7 : -0.7;
        }
      }

      int intSample = (sample * 32767).clamp(-32768, 32767).toInt();
      buffer.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  /// Trigger crisp scanner success: High beep (1750 Hz) + 50ms light haptic pulse
  static Future<void> triggerSuccessFeedback() async {
    // 1. Haptics
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib == true) {
        await Vibration.vibrate(duration: 50);
      } else {
        await HapticFeedback.lightImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
    }

    // 2. Audio (High Crisp Beep ~1750Hz, 70ms)
    try {
      _cachedSuccessBeep ??= _generateWav(
        frequency: 1750,
        durationSeconds: 0.08,
      );
      await _player.stop();
      await _player.play(BytesSource(_cachedSuccessBeep!));
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  /// Trigger failure: Low double-buzz (350 Hz) + heavy double haptic pulse
  static Future<void> triggerFailureFeedback() async {
    // 1. Haptics (Heavy Double Pulse: 100ms on, 80ms off, 100ms on)
    try {
      final hasCustom = await Vibration.hasCustomVibrationsSupport();
      if (hasCustom == true) {
        await Vibration.vibrate(pattern: [0, 90, 70, 90]);
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    // 2. Audio (Low Double Buzz ~350Hz, 250ms)
    try {
      _cachedErrorBuzz ??= _generateWav(
        frequency: 350,
        durationSeconds: 0.25,
        isDoubleBuzz: true,
      );
      await _player.stop();
      await _player.play(BytesSource(_cachedErrorBuzz!));
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }
}
