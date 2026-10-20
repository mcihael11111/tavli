import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/gameplay/services/game_audio.dart';
import 'package:tavli/gameplay/services/sfx_player.dart';
import 'package:tavli/shared/services/audio_service.dart' show SfxType;

class FakePlayer implements SfxPlayer {
  FakePlayer(this.id, {this.failAssets = false});
  final int id;
  final bool failAssets;
  final loads = <String>[];
  final volumes = <double>[];
  int plays = 0;
  bool disposed = false;

  @override
  Future<void> setAsset(String path) async {
    if (failAssets) throw StateError('no asset');
    loads.add('asset:$path');
  }

  @override
  Future<void> setBytes(Uint8List wav) async => loads.add('bytes');

  @override
  Future<void> setVolume(double v) async => volumes.add(v);

  @override
  Future<void> replay() async => plays++;

  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  late List<FakePlayer> players;
  late double volume;
  GameAudio make({bool failAssets = false}) {
    players = [];
    volume = 1.0;
    return GameAudio(
      playerFactory: () {
        final p = FakePlayer(players.length, failAssets: failAssets);
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
}
