// ignore_for_file: experimental_member_use
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'sound_generator.dart';

/// Sound effect types matching the audio design spec.
enum SfxType {
  // Checker sounds.
  checkerPickup,
  checkerPlace,
  checkerSlide,
  checkerStack,
  checkerHit,
  checkerBarEntry,
  checkerBearOff,

  // Dice sounds.
  diceShake,
  diceRoll,
  diceBounce,
  diceSettle,
  diceDoublesChime,

  // UI sounds.
  buttonTap,
  menuOpen,
  menuClose,
  toggleSwitch,
  notification,

  // Game events.
  turnStart,
  gameStart,
  gameWin,
  gameLose,
  gammonWin,
  backgammonWin,
  doubleOffer,
  doubleAccept,
  doubleRefuse,
}

/// Music tracks for the adaptive 4-layer system.
enum MusicLayer {
  base,
  percussion,
  melody,
  tension,
}

/// Kafeneio ambiance layers.
enum AmbianceLayer {
  roomTone,
  coffeeSounds,
  outdoorAmbience,
  socialMurmur,
  distantRadio,
}

/// Asset path for an SFX file, or null if no asset exists.
///
/// Returns a list of paths for types with multiple variants (dice rolls).
const _sfxAssets = <SfxType, List<String>>{
  SfxType.buttonTap: ['assets/audio/sfx/button_tap.mp3'],
  SfxType.diceRoll: [
    'assets/audio/sfx/dice_roll_1.mp3',
    'assets/audio/sfx/dice_roll_2.mp3',
    'assets/audio/sfx/dice_roll_3.mp3',
    'assets/audio/sfx/dice_roll_4.mp3',
  ],
  SfxType.diceShake: [
    'assets/audio/sfx/dice_roll_1.mp3',
    'assets/audio/sfx/dice_roll_2.mp3',
    'assets/audio/sfx/dice_roll_3.mp3',
    'assets/audio/sfx/dice_roll_4.mp3',
  ],
  SfxType.diceBounce: [
    'assets/audio/sfx/dice_roll_3.mp3',
    'assets/audio/sfx/dice_roll_4.mp3',
  ],
  SfxType.doubleOffer: ['assets/audio/sfx/double_offer.mp3'],
  SfxType.gameWin: ['assets/audio/sfx/game_win.mp3'],
  SfxType.gammonWin: ['assets/audio/sfx/game_win.mp3'],
  SfxType.backgammonWin: ['assets/audio/sfx/game_win.mp3'],
  SfxType.gameLose: ['assets/audio/sfx/game_lose.mp3'],
};

/// Audio manager — handles SFX, music, voice, and ambiance.
///
/// Prefers real audio asset files when available, falling back to
/// procedurally generated WAV buffers. Fires haptic feedback on all
/// platforms regardless of audio state.
class AudioService {
  double _musicVolume = 0.7;
  double _sfxVolume = 1.0;
  double _voiceVolume = 0.8;
  bool _isInitialized = false;

  AudioPlayer? _sfxPlayer;
  AudioPlayer? _musicPlayer;

  final _rng = Random();

  /// Pre-generated sound buffers (fallback for types without asset files).
  final Map<SfxType, Uint8List> _sfxBuffers = {};

  /// Tracks which asset files loaded successfully.
  final Set<SfxType> _assetAvailable = {};

  final Set<MusicLayer> _activeMusicLayers = {MusicLayer.base};
  final Set<AmbianceLayer> _activeAmbianceLayers = {
    AmbianceLayer.roomTone,
    AmbianceLayer.coffeeSounds,
  };

  /// Initialize audio engine, probe assets, and pre-generate fallback buffers.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _sfxPlayer = AudioPlayer();
    _musicPlayer = AudioPlayer();

    // Probe which asset files actually exist.
    for (final entry in _sfxAssets.entries) {
      try {
        // Try loading the first variant to verify the asset bundle has it.
        await rootBundle.load(entry.value.first);
        _assetAvailable.add(entry.key);
      } catch (_) {
        // Asset not found — will use procedural fallback.
      }
    }

    // Pre-generate fallback buffers for all types.
    _sfxBuffers[SfxType.checkerPickup] = SoundGenerator.checkerPickup();
    _sfxBuffers[SfxType.checkerPlace] = SoundGenerator.checkerPlace();
    _sfxBuffers[SfxType.checkerSlide] = SoundGenerator.checkerPlace();
    _sfxBuffers[SfxType.checkerStack] = SoundGenerator.checkerPlace();
    _sfxBuffers[SfxType.checkerHit] = SoundGenerator.checkerHit();
    _sfxBuffers[SfxType.checkerBarEntry] = SoundGenerator.checkerHit();
    _sfxBuffers[SfxType.checkerBearOff] = SoundGenerator.bearOff();
    _sfxBuffers[SfxType.diceRoll] = SoundGenerator.diceRoll();
    _sfxBuffers[SfxType.diceShake] = SoundGenerator.diceRoll();
    _sfxBuffers[SfxType.diceBounce] = SoundGenerator.diceRoll();
    _sfxBuffers[SfxType.diceSettle] = SoundGenerator.checkerPlace();
    _sfxBuffers[SfxType.diceDoublesChime] = SoundGenerator.doublesChime();
    _sfxBuffers[SfxType.buttonTap] = SoundGenerator.uiClick();
    _sfxBuffers[SfxType.menuOpen] = SoundGenerator.uiClick();
    _sfxBuffers[SfxType.menuClose] = SoundGenerator.uiClick();
    _sfxBuffers[SfxType.toggleSwitch] = SoundGenerator.uiClick();
    _sfxBuffers[SfxType.notification] = SoundGenerator.doublesChime();
    _sfxBuffers[SfxType.gameWin] = SoundGenerator.gameWin();
    _sfxBuffers[SfxType.gameLose] = SoundGenerator.gameLose();
    _sfxBuffers[SfxType.gammonWin] = SoundGenerator.gameWin();
    _sfxBuffers[SfxType.backgammonWin] = SoundGenerator.gameWin();
    _sfxBuffers[SfxType.doubleOffer] = SoundGenerator.doublesChime();
    _sfxBuffers[SfxType.doubleAccept] = SoundGenerator.uiClick();
    _sfxBuffers[SfxType.doubleRefuse] = SoundGenerator.uiClick();
    _sfxBuffers[SfxType.turnStart] = SoundGenerator.uiClick();
    _sfxBuffers[SfxType.gameStart] = SoundGenerator.doublesChime();

    _isInitialized = true;
  }

  /// Play a sound effect with haptic feedback.
  Future<void> playSfx(SfxType type) async {
    // Always fire haptic feedback.
    _playHaptic(type);

    if (_sfxVolume == 0) return;

    // Prefer real asset file if available.
    if (_assetAvailable.contains(type)) {
      try {
        final paths = _sfxAssets[type]!;
        final path = paths[_rng.nextInt(paths.length)];
        await _sfxPlayer!.setAudioSource(AudioSource.asset(path));
        await _sfxPlayer!.setVolume(_sfxVolume);
        await _sfxPlayer!.seek(Duration.zero);
        await _sfxPlayer!.play();
        return;
      } catch (_) {
        // Fall through to procedural fallback.
      }
    }

    // Procedural fallback.
    final buffer = _sfxBuffers[type];
    if (buffer != null && _sfxPlayer != null) {
      try {
        final source = _WavAudioSource(buffer);
        await _sfxPlayer!.setAudioSource(source);
        await _sfxPlayer!.setVolume(_sfxVolume);
        await _sfxPlayer!.seek(Duration.zero);
        await _sfxPlayer!.play();
      } catch (_) {
        // Silently fail — haptic feedback already fired.
      }
    }
  }

  /// Fire appropriate haptic feedback for the sound type.
  void _playHaptic(SfxType type) {
    switch (type) {
      case SfxType.checkerPickup:
      case SfxType.buttonTap:
      case SfxType.toggleSwitch:
        HapticFeedback.selectionClick();
      case SfxType.checkerPlace:
      case SfxType.checkerSlide:
      case SfxType.checkerStack:
      case SfxType.checkerBarEntry:
      case SfxType.checkerBearOff:
      case SfxType.diceSettle:
      case SfxType.menuOpen:
      case SfxType.menuClose:
        HapticFeedback.lightImpact();
      case SfxType.diceRoll:
      case SfxType.diceBounce:
      case SfxType.doubleOffer:
      case SfxType.doubleAccept:
      case SfxType.doubleRefuse:
        HapticFeedback.mediumImpact();
      case SfxType.checkerHit:
      case SfxType.diceDoublesChime:
      case SfxType.gameWin:
      case SfxType.gameLose:
      case SfxType.gammonWin:
      case SfxType.backgammonWin:
        HapticFeedback.heavyImpact();
      case SfxType.diceShake:
      case SfxType.notification:
      case SfxType.turnStart:
      case SfxType.gameStart:
        HapticFeedback.lightImpact();
    }
  }

  /// Play a Mikhail voice line.
  Future<void> playVoiceLine(String lineKey) async {
    if (_voiceVolume == 0) return;
    // Voice lines require real audio files — placeholder for now.
  }

  // ── Music Layer System ──────────────────────────────────────

  Future<void> startMusic() async {
    if (_musicVolume == 0) return;
    _activeMusicLayers.add(MusicLayer.base);

    try {
      await _musicPlayer!.setAudioSource(
        AudioSource.asset('assets/audio/music/greek_taverna_background.mp3'),
      );
      await _musicPlayer!.setLoopMode(LoopMode.one);
      await _musicPlayer!.setVolume(_musicVolume);
      await _musicPlayer!.play();
    } catch (_) {
      // Music file not available — silent fallback.
    }
  }

  Future<void> stopMusic() async {
    _activeMusicLayers.clear();
    try {
      await _musicPlayer?.stop();
    } catch (_) {}
  }

  void enableMusicLayer(MusicLayer layer) {
    _activeMusicLayers.add(layer);
  }

  void disableMusicLayer(MusicLayer layer) {
    _activeMusicLayers.remove(layer);
  }

  void adaptMusicToGameState({
    required bool isPlayerAhead,
    required bool isEndgame,
    required bool isCloseGame,
  }) {
    if (isEndgame && isCloseGame) {
      enableMusicLayer(MusicLayer.tension);
      disableMusicLayer(MusicLayer.melody);
    } else if (isPlayerAhead) {
      enableMusicLayer(MusicLayer.melody);
      disableMusicLayer(MusicLayer.tension);
    } else {
      disableMusicLayer(MusicLayer.melody);
      disableMusicLayer(MusicLayer.tension);
    }
  }

  // ── Ambiance ────────────────────────────────────────────────

  Future<void> startAmbiance() async {
    // Ambiance requires real audio files — placeholder for now.
  }

  void updateAmbianceForTimeOfDay() {
    final hour = DateTime.now().hour;
    _activeAmbianceLayers.clear();
    _activeAmbianceLayers.add(AmbianceLayer.roomTone);

    if (hour >= 7 && hour < 12) {
      _activeAmbianceLayers.add(AmbianceLayer.coffeeSounds);
      _activeAmbianceLayers.add(AmbianceLayer.outdoorAmbience);
    } else if (hour >= 12 && hour < 18) {
      _activeAmbianceLayers.add(AmbianceLayer.socialMurmur);
      _activeAmbianceLayers.add(AmbianceLayer.outdoorAmbience);
    } else {
      _activeAmbianceLayers.add(AmbianceLayer.distantRadio);
    }
  }

  // ── Volume Controls ─────────────────────────────────────────

  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0, 1);
    _musicPlayer?.setVolume(_musicVolume);
  }

  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0, 1);
  }

  void setVoiceVolume(double volume) {
    _voiceVolume = volume.clamp(0, 1);
  }

  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  double get voiceVolume => _voiceVolume;

  Future<void> dispose() async {
    await stopMusic();
    await _sfxPlayer?.dispose();
    await _musicPlayer?.dispose();
  }
}

/// Audio source from in-memory WAV bytes.
class _WavAudioSource extends StreamAudioSource {
  final Uint8List _bytes;

  _WavAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final effectiveStart = start ?? 0;
    final effectiveEnd = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: effectiveEnd - effectiveStart,
      offset: effectiveStart,
      stream: Stream.value(_bytes.sublist(effectiveStart, effectiveEnd)),
      contentType: 'audio/wav',
    );
  }
}

/// Haptic feedback synchronized with audio.
class HapticService {
  Future<void> lightTap() async => HapticFeedback.lightImpact();
  Future<void> mediumTap() async => HapticFeedback.mediumImpact();
  Future<void> heavyTap() async => HapticFeedback.heavyImpact();
  Future<void> selectionClick() async => HapticFeedback.selectionClick();
}

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

final hapticServiceProvider = Provider<HapticService>((ref) {
  return HapticService();
});
