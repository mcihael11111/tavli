import 'dart:math';
import 'dart:typed_data';

/// Procedural audio generator for game sound effects.
///
/// Generates short WAV byte buffers for different game sounds.
/// Used as a fallback when real audio asset files aren't available.
class SoundGenerator {
  static const int _sampleRate = 44100;

  /// Generate a WAV file as bytes for a given sound type.
  static Uint8List generateWav({
    required double frequency,
    required double duration,
    double volume = 0.5,
    WaveShape shape = WaveShape.sine,
    double decay = 0.0,
  }) {
    final numSamples = (_sampleRate * duration).toInt();
    final samples = Float64List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      double value;

      switch (shape) {
        case WaveShape.sine:
          value = sin(2 * pi * frequency * t);
        case WaveShape.square:
          value = sin(2 * pi * frequency * t) > 0 ? 1.0 : -1.0;
        case WaveShape.noise:
          value = Random().nextDouble() * 2 - 1;
        case WaveShape.click:
          // Short exponential decay impulse.
          value = sin(2 * pi * frequency * t) * exp(-t * 50);
      }

      // Apply volume and decay envelope.
      final envelope = decay > 0 ? exp(-t * decay) : 1.0;
      samples[i] = value * volume * envelope;
    }

    return _samplesToWav(samples);
  }

  /// Checker place sound: short wooden thud.
  static Uint8List checkerPlace() => generateWav(
        frequency: 180,
        duration: 0.08,
        volume: 0.4,
        shape: WaveShape.click,
        decay: 40,
      );

  /// Checker pickup sound: light tap.
  static Uint8List checkerPickup() => generateWav(
        frequency: 320,
        duration: 0.05,
        volume: 0.25,
        shape: WaveShape.click,
        decay: 60,
      );

  /// Checker hit sound: sharp impact.
  static Uint8List checkerHit() => generateWav(
        frequency: 120,
        duration: 0.15,
        volume: 0.6,
        shape: WaveShape.click,
        decay: 25,
      );

  /// Dice roll sound: rattling noise burst.
  static Uint8List diceRoll() {
    final numSamples = (_sampleRate * 0.3).toInt();
    final samples = Float64List(numSamples);
    final rng = Random(42);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      // Mix noise with resonant tone for "rattle" effect.
      final noise = rng.nextDouble() * 2 - 1;
      final tone = sin(2 * pi * 400 * t) * 0.3;
      final envelope = exp(-t * 8);
      samples[i] = (noise * 0.6 + tone) * envelope * 0.4;
    }

    return _samplesToWav(samples);
  }

  /// Dice doubles chime: pleasant double-note.
  static Uint8List doublesChime() {
    final numSamples = (_sampleRate * 0.25).toInt();
    final samples = Float64List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final note1 = sin(2 * pi * 523 * t); // C5
      final note2 = sin(2 * pi * 659 * t); // E5
      final envelope = exp(-t * 6);
      samples[i] = (note1 + note2) * 0.2 * envelope;
    }

    return _samplesToWav(samples);
  }

  /// Bear off sound: ascending tone.
  static Uint8List bearOff() {
    final numSamples = (_sampleRate * 0.15).toInt();
    final samples = Float64List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final freq = 300 + t * 800; // Rising pitch
      final envelope = exp(-t * 10);
      samples[i] = sin(2 * pi * freq * t) * 0.35 * envelope;
    }

    return _samplesToWav(samples);
  }

  /// Win sound: triumphant chord.
  static Uint8List gameWin() {
    final numSamples = (_sampleRate * 0.5).toInt();
    final samples = Float64List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final c = sin(2 * pi * 523 * t); // C5
      final e = sin(2 * pi * 659 * t); // E5
      final g = sin(2 * pi * 784 * t); // G5
      final envelope = exp(-t * 3);
      samples[i] = (c + e + g) * 0.15 * envelope;
    }

    return _samplesToWav(samples);
  }

  /// Lose sound: descending tone.
  static Uint8List gameLose() {
    final numSamples = (_sampleRate * 0.4).toInt();
    final samples = Float64List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final freq = 400 - t * 300; // Falling pitch
      final envelope = exp(-t * 4);
      samples[i] = sin(2 * pi * freq * t) * 0.3 * envelope;
    }

    return _samplesToWav(samples);
  }

  /// UI click sound.
  static Uint8List uiClick() => generateWav(
        frequency: 600,
        duration: 0.03,
        volume: 0.2,
        shape: WaveShape.click,
        decay: 80,
      );

  /// Convert float samples to a 16-bit PCM WAV byte buffer.
  static Uint8List _samplesToWav(Float64List samples) {
    final numSamples = samples.length;
    final dataSize = numSamples * 2; // 16-bit = 2 bytes per sample
    final fileSize = 44 + dataSize;

    final buffer = ByteData(fileSize);
    int offset = 0;

    // RIFF header.
    buffer.setUint8(offset++, 0x52); // R
    buffer.setUint8(offset++, 0x49); // I
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint32(offset, fileSize - 8, Endian.little);
    offset += 4;
    buffer.setUint8(offset++, 0x57); // W
    buffer.setUint8(offset++, 0x41); // A
    buffer.setUint8(offset++, 0x56); // V
    buffer.setUint8(offset++, 0x45); // E

    // fmt chunk.
    buffer.setUint8(offset++, 0x66); // f
    buffer.setUint8(offset++, 0x6D); // m
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x20); // (space)
    buffer.setUint32(offset, 16, Endian.little); // chunk size
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // PCM format
    offset += 2;
    buffer.setUint16(offset, 1, Endian.little); // mono
    offset += 2;
    buffer.setUint32(offset, _sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, _sampleRate * 2, Endian.little); // byte rate
    offset += 4;
    buffer.setUint16(offset, 2, Endian.little); // block align
    offset += 2;
    buffer.setUint16(offset, 16, Endian.little); // bits per sample
    offset += 2;

    // data chunk.
    buffer.setUint8(offset++, 0x64); // d
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    // Sample data.
    for (int i = 0; i < numSamples; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      final intSample = (clamped * 32767).toInt();
      buffer.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}

enum WaveShape { sine, square, noise, click }
