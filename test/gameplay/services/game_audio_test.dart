import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/gameplay/services/game_audio.dart';
import 'package:tavli/gameplay/services/sfx_player.dart';
import 'package:tavli/shared/services/audio_service.dart' show SfxType;

class FakePlayer implements SfxPlayer {
  FakePlayer(this.id, {this.failAssets = false, this.gate});
  final int id;
  final bool failAssets;

  /// When set, loads wait for it.
  final Future<void>? gate;

  /// setVolume calls left that throw.
  int failVolumes = 0;
  final loads = <String>[];
  final volumes = <double>[];
  int plays = 0;
  bool disposed = false;

  @override
  Future<void> setAsset(String path) async {
    await gate;
    if (failAssets) throw StateError('no asset');
    loads.add('asset:$path');
  }

  @override
  Future<void> setBytes(Uint8List wav) async => loads.add('bytes');

  @override
  Future<void> setVolume(double v) async {
    volumes.add(v);
    if (failVolumes > 0) {
      failVolumes--;
      throw StateError('volume');
    }
  }

  @override
  Future<void> replay() async => plays++;

  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  late List<FakePlayer> players;
  late double volume;
  GameAudio make({bool failAssets = false, Future<void>? gate}) {
    players = [];
    volume = 1.0;
    return GameAudio(
      playerFactory: () {
        final p =
            FakePlayer(players.length, failAssets: failAssets, gate: gate);
        players.add(p);
        return p;
      },
      volume: () => volume,
    );
  }

  List<FakePlayer> played() => players.where((p) => p.plays > 0).toList();

  test('preloads once, even if init is called again', () async {
    final audio = make();
    await audio.init();
    final count = players.length;
    final loads = players.map((p) => p.loads.length).toList();
    await audio.init();
    expect(players.length, count);
    expect(players.map((p) => p.loads.length).toList(), loads);
    expect(players.every((p) => p.loads.length == 1), isTrue);
  });

  test('play does not reload', () async {
    final audio = make();
    await audio.init();
    for (final t in SfxType.values) {
      audio.play(t);
    }
    await pumpEventQueue();
    expect(players.every((p) => p.loads.length == 1), isTrue);
    expect(played(), isNotEmpty);
  });

  test('every SfxType plays exactly one player', () async {
    final audio = make();
    await audio.init();
    for (final t in SfxType.values) {
      for (final p in players) {
        p.plays = 0;
      }
      audio.play(t);
      await pumpEventQueue();
      expect(played(), hasLength(1), reason: '$t');
    }
  });

  test('volume applied from the setting; zero volume is silent', () async {
    final audio = make();
    await audio.init();
    volume = 0.4;
    audio.play(SfxType.diceRoll);
    await pumpEventQueue();
    expect(played().single.volumes.last, 0.4);

    for (final p in players) {
      p.plays = 0;
    }
    volume = 0;
    audio.play(SfxType.diceRoll);
    await pumpEventQueue();
    expect(played(), isEmpty);
  });

  test('overlapping checker sounds use different players', () async {
    final audio = make();
    await audio.init();
    final used = <int>{};
    for (var i = 0; i < GameAudio.checkerPoolSize; i++) {
      for (final p in players) {
        p.plays = 0;
      }
      audio.play(SfxType.checkerPlace);
      await pumpEventQueue();
      used.add(played().single.id);
    }
    expect(used, hasLength(GameAudio.checkerPoolSize));
  });

  test('falls back to procedural sounds when assets are missing', () async {
    final audio = make(failAssets: true);
    await audio.init();
    expect(players.every((p) => p.loads.single == 'bytes'), isTrue);
    audio.play(SfxType.gameWin);
    await pumpEventQueue();
    expect(played(), hasLength(1));
  });

  test('play before init is a silent no-op', () async {
    final audio = make();
    audio.play(SfxType.checkerHit);
    await pumpEventQueue();
    expect(players, isEmpty);
  });

  test('dispose releases every player', () async {
    final audio = make();
    await audio.init();
    await audio.dispose();
    expect(players.every((p) => p.disposed), isTrue);
  });

  test('dispose during init disposes the players the load makes', () async {
    final gate = Completer<void>();
    final audio = make(gate: gate.future);
    final loading = audio.init();
    await audio.dispose();
    gate.complete();
    await loading;
    expect(players, isNotEmpty);
    expect(players.every((p) => p.disposed), isTrue);
    audio.play(SfxType.diceRoll);
    await pumpEventQueue();
    expect(played(), isEmpty);
  });

  test('init after dispose loads afresh', () async {
    final audio = make();
    await audio.init();
    await audio.dispose();
    final before = players.length;
    await audio.init();
    expect(players.length, greaterThan(before));
    audio.play(SfxType.diceRoll);
    await pumpEventQueue();
    expect(played(), hasLength(1));
  });

  test('a failed setVolume is retried on the next play', () async {
    final audio = make();
    await audio.init();
    volume = 0.5;
    for (final p in players) {
      p.failVolumes = 1;
    }
    audio.play(SfxType.diceRoll);
    await pumpEventQueue();
    final p = played().single;
    expect(p.volumes, [0.5]);
    audio.play(SfxType.diceRoll);
    await pumpEventQueue();
    expect(p.volumes, [0.5, 0.5]);
    audio.play(SfxType.diceRoll);
    await pumpEventQueue();
    expect(p.volumes, [0.5, 0.5], reason: 'cached once applied');
  });
}
