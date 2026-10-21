// StreamAudioSource is marked experimental in just_audio.
// ignore_for_file: experimental_member_use
/// One preloaded sound-effect player (design §5.2), injectable for tests.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

/// A player that is loaded once and replayed many times.
abstract interface class SfxPlayer {
  /// Loads an asset; throws if it is missing.
  Future<void> setAsset(String path);

  /// Loads in-memory WAV bytes.
  Future<void> setBytes(Uint8List wav);

  Future<void> setVolume(double v);

  /// Plays the loaded sound from the start, without reloading it.
  Future<void> replay();

  Future<void> dispose();
}

/// Creates a player; tests inject fakes.
typedef SfxPlayerFactory = SfxPlayer Function();

/// The `just_audio` player.
class JustAudioSfxPlayer implements SfxPlayer {
  final AudioPlayer _p = AudioPlayer();

  @override
  Future<void> setAsset(String path) =>
      _p.setAudioSource(AudioSource.asset(path));

  @override
  Future<void> setBytes(Uint8List wav) =>
      _p.setAudioSource(_WavAudioSource(wav));

  @override
  Future<void> setVolume(double v) => _p.setVolume(v);

  @override
  Future<void> replay() async {
    await _p.seek(Duration.zero);
    // play() completes only when playback stops, so it is not awaited.
    unawaited(_p.play().catchError((_) {}));
  }

  @override
  Future<void> dispose() => _p.dispose();
}

/// Audio source over in-memory WAV bytes.
class _WavAudioSource extends StreamAudioSource {
  final Uint8List _bytes;

  _WavAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final s = start ?? 0;
    final e = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: e - s,
      offset: s,
      stream: Stream.value(_bytes.sublist(s, e)),
      contentType: 'audio/wav',
    );
  }
}
