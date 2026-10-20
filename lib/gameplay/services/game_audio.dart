/// Pooled, preloaded gameplay sound effects (design §5.2).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tavli/shared/services/audio_service.dart' show SfxType;
import 'package:tavli/shared/services/settings_service.dart';
import 'package:tavli/shared/services/sound_generator.dart';

import 'sfx_player.dart';

/// Gameplay SFX. Every sound is loaded once by [init] into its own player
/// (a pool of [checkerPoolSize] for checker sounds, so overlapping moves do
/// not cut each other off); [play] only replays. A missing asset falls back
/// to the procedural sound from [SoundGenerator].
///
/// SFX types that share a sound share one canonical pool ([canonical]), so
/// the 26 types need 10 sounds (21 players).
class GameAudio {
  /// Players per checker sound.
  static const checkerPoolSize = 3;

  static const _assets = <SfxType, String>{
    SfxType.buttonTap: 'assets/audio/sfx/button_tap.mp3',
    SfxType.diceRoll: 'assets/audio/sfx/dice_roll_1.mp3',
    SfxType.doubleOffer: 'assets/audio/sfx/double_offer.mp3',
    SfxType.gameWin: 'assets/audio/sfx/game_win.mp3',
    SfxType.gameLose: 'assets/audio/sfx/game_lose.mp3',
  };

  static const _checkerSounds = {
    SfxType.checkerPickup,
    SfxType.checkerPlace,
    SfxType.checkerHit,
    SfxType.checkerBearOff,
  };

  final SfxPlayerFactory _factory;
  final double Function() _volume;
  final Map<SfxType, _Pool> _pools = {};
  Future<void>? _init;

  GameAudio({
    SfxPlayerFactory? playerFactory,
    required double Function() volume,
  })  : _factory = playerFactory ?? JustAudioSfxPlayer.new,
        _volume = volume;

  static GameAudio? _instance;

  /// The app-wide instance, at the persisted SFX volume.
  static GameAudio get instance =>
      _instance ??= GameAudio(volume: () => SettingsService.instance.sfxVolume);

  /// The sound [t] plays.
  static SfxType canonical(SfxType t) => switch (t) {
        SfxType.checkerSlide ||
        SfxType.checkerStack ||
        SfxType.diceSettle =>
          SfxType.checkerPlace,
        SfxType.checkerBarEntry => SfxType.checkerHit,
        SfxType.diceShake || SfxType.diceBounce => SfxType.diceRoll,
        SfxType.gammonWin || SfxType.backgammonWin => SfxType.gameWin,
        SfxType.menuOpen ||
        SfxType.menuClose ||
        SfxType.toggleSwitch ||
        SfxType.turnStart ||
        SfxType.doubleAccept ||
        SfxType.doubleRefuse =>
          SfxType.buttonTap,
        SfxType.notification || SfxType.gameStart => SfxType.diceDoublesChime,
        _ => t,
      };

  /// Preloads every sound once; later calls return the same future. Never
  /// throws: a sound that fails to load stays silent.
  Future<void> init() => _init ??= _load();

  Future<void> _load() async {
    final sounds = SfxType.values.map(canonical).toSet();
    await Future.wait(sounds.map((t) async {
      final size = _checkerSounds.contains(t) ? checkerPoolSize : 1;
      final players = [for (var i = 0; i < size; i++) _factory()];
      final loaded = await Future.wait(players.map((p) => _loadOne(p, t)));
      _pools[t] = _Pool([
        for (var i = 0; i < size; i++)
          if (loaded[i]) _Slot(players[i]),
      ]);
    }));
  }

  Future<bool> _loadOne(SfxPlayer p, SfxType t) async {
    final asset = _assets[t];
    if (asset != null) {
      try {
        await p.setAsset(asset);
        return true;
      } catch (_) {
        // Missing asset: fall through to the procedural sound.
      }
    }
    try {
      await p.setBytes(_procedural(t));
      return true;
    } catch (e) {
      debugPrint('GameAudio: $t failed to load: $e');
      return false;
    }
  }

  static Uint8List _procedural(SfxType t) => switch (t) {
        SfxType.checkerPickup => SoundGenerator.checkerPickup(),
        SfxType.checkerHit => SoundGenerator.checkerHit(),
        SfxType.checkerBearOff => SoundGenerator.bearOff(),
        SfxType.diceRoll => SoundGenerator.diceRoll(),
        SfxType.diceDoublesChime ||
        SfxType.doubleOffer =>
          SoundGenerator.doublesChime(),
        SfxType.gameWin => SoundGenerator.gameWin(),
        SfxType.gameLose => SoundGenerator.gameLose(),
        SfxType.buttonTap => SoundGenerator.uiClick(),
        _ => SoundGenerator.checkerPlace(),
      };

  /// Plays [t] at the current SFX volume. Silent before [init] completes,
  /// at volume 0, or if the sound failed to load.
  void play(SfxType t) {
    final slot = _pools[canonical(t)]?.next();
    if (slot == null) return;
    final v = _volume().clamp(0.0, 1.0);
    if (v <= 0) return;
    if (slot.volume != v) {
      slot.volume = v;
      unawaited(slot.player.setVolume(v).catchError((_) {}));
    }
    unawaited(slot.player.replay().catchError((_) {}));
  }

  Future<void> dispose() async {
    final players = [
      for (final pool in _pools.values)
        for (final s in pool.slots) s.player,
    ];
    _pools.clear();
    await Future.wait(players.map((p) => p.dispose().catchError((_) {})));
  }
}

class _Slot {
  final SfxPlayer player;
  double? volume;
  _Slot(this.player);
}

/// Round-robin over the loaded players of one sound.
class _Pool {
  final List<_Slot> slots;
  int _next = 0;
  _Pool(this.slots);

  _Slot? next() {
    if (slots.isEmpty) return null;
    final s = slots[_next];
    _next = (_next + 1) % slots.length;
    return s;
  }
}

final gameAudioProvider = Provider<GameAudio>((ref) => GameAudio.instance);
