/// What a match is set up with (design §3, `MatchSetup`).
library;

import 'package:flutter/foundation.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/ai/personality/bot_personality.dart';
import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';

import '../adapters/difficulty_adapter.dart';

/// Who plays the two seats.
enum MatchMode {
  /// The local player is [MatchSetup.humanSide]; the bot plays the other.
  vsBot,

  /// Two people share the device: both seats are human.
  passAndPlay,
}

/// The arguments of one match controller (the provider family key), so it
/// has value equality.
@immutable
final class MatchSetup {
  MatchSetup({
    required this.mode,
    required this.variant,
    this.difficulty = DifficultyLevel.easy,
    this.personality = BotPersonality.mikhail,
    bool? cubeEnabled,
    this.seed,
    this.marathon = false,
  }) : cubeEnabled = cubeEnabled ?? variant.rules.cube.enabledByDefault;

  final MatchMode mode;
  final Variant variant;

  /// The app difficulty: the bot level, teaching and what is recorded.
  final DifficultyLevel difficulty;
  final BotPersonality personality;

  /// Whether the match uses the cube (only where the variant has one).
  final bool cubeEnabled;

  /// Seeds the dice (and the bot request seeds); null for
  /// `Random.secure()`. Tests only.
  final int? seed;

  /// Forwarded from the route; unused until SP5.
  final bool marathon;

  /// The local player's side in [MatchMode.vsBot].
  static const humanSide = Side.one;

  /// The bot's side in [MatchMode.vsBot].
  static const botSide = Side.two;

  /// The level the bot searches at.
  BotLevel get level => difficulty.botSetting.level;

  /// Teaching analysis for the human (`easyWithHelp`, vs bot only).
  bool get teaching =>
      mode == MatchMode.vsBot && difficulty.botSetting.teaching;

  /// Whether [s] is played by the bot.
  bool isBot(Side s) => mode == MatchMode.vsBot && s == botSide;

  /// The core match: one game of [variant] (Tawla 31 plays to its fixed
  /// target).
  MatchConfig get config =>
      MatchConfig.single(variant, cubeEnabled: cubeEnabled);

  @override
  bool operator ==(Object other) =>
      other is MatchSetup &&
      other.mode == mode &&
      other.variant == variant &&
      other.difficulty == difficulty &&
      other.personality == personality &&
      other.cubeEnabled == cubeEnabled &&
      other.seed == seed &&
      other.marathon == marathon;

  @override
  int get hashCode => Object.hash(
      mode, variant, difficulty, personality, cubeEnabled, seed, marathon);

  @override
  String toString() => 'MatchSetup(${mode.name}, ${variant.name}, '
      '${difficulty.name}, cube $cubeEnabled, seed $seed)';
}
