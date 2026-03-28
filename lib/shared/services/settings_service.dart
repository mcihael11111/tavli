import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/tradition.dart';
import '../../features/ai/personality/bot_personality.dart';

/// Persists user settings to SharedPreferences.
class SettingsService {
  static const _themeKey = 'tavli_theme';
  static const _musicVolKey = 'tavli_music_vol';
  static const _sfxVolKey = 'tavli_sfx_vol';
  static const _voiceVolKey = 'tavli_voice_vol';
  static const _langKey = 'tavli_mikhail_lang';
  static const _pipCountKey = 'tavli_pip_count';
  static const _moveConfirmKey = 'tavli_move_confirm';
  static const _boardSetKey = 'tavli_board_set';
  static const _checkerSetKey = 'tavli_checker_set';
  static const _diceSetKey = 'tavli_dice_set';
  static const _autoDoublesKey = 'tavli_auto_doubles';
  static const _beaversKey = 'tavli_beavers';
  static const _jacobyKey = 'tavli_jacoby';
  static const _personalityKey = 'tavli_bot_personality';
  static const _greekLevelKey = 'tavli_greek_level';
  static const _traditionKey = 'tables_tradition';
  static const _languageLevelKey = 'tables_language_level';
  static const _playerNameKey = 'tavli_player_name';

  final SharedPreferences _prefs;

  SettingsService._(this._prefs);

  static SettingsService? _instance;

  static Future<SettingsService> initialize() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = SettingsService._(prefs);
    return _instance!;
  }

  static SettingsService get instance {
    if (_instance == null) {
      throw StateError('SettingsService not initialized.');
    }
    return _instance!;
  }

  // ── Theme ──────────────────────────────────────────────────
  ThemeMode get themeMode {
    final v = _prefs.getString(_themeKey);
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }
  set themeMode(ThemeMode m) => _prefs.setString(_themeKey, m.name);

  // ── Audio ──────────────────────────────────────────────────
  double get musicVolume => _prefs.getDouble(_musicVolKey) ?? 0.7;
  set musicVolume(double v) => _prefs.setDouble(_musicVolKey, v);

  double get sfxVolume => _prefs.getDouble(_sfxVolKey) ?? 1.0;
  set sfxVolume(double v) => _prefs.setDouble(_sfxVolKey, v);

  double get voiceVolume => _prefs.getDouble(_voiceVolKey) ?? 0.8;
  set voiceVolume(double v) => _prefs.setDouble(_voiceVolKey, v);

  String get mikhailLanguage => _prefs.getString(_langKey) ?? 'mix';
  set mikhailLanguage(String v) => _prefs.setString(_langKey, v);

  // ── Game ───────────────────────────────────────────────────
  bool get showPipCount => _prefs.getBool(_pipCountKey) ?? false;
  set showPipCount(bool v) => _prefs.setBool(_pipCountKey, v);

  bool get moveConfirmation => _prefs.getBool(_moveConfirmKey) ?? false;
  set moveConfirmation(bool v) => _prefs.setBool(_moveConfirmKey, v);

  bool get autoDoubles => _prefs.getBool(_autoDoublesKey) ?? false;
  set autoDoubles(bool v) => _prefs.setBool(_autoDoublesKey, v);

  bool get beavers => _prefs.getBool(_beaversKey) ?? false;
  set beavers(bool v) => _prefs.setBool(_beaversKey, v);

  bool get jacobyRule => _prefs.getBool(_jacobyKey) ?? false;
  set jacobyRule(bool v) => _prefs.setBool(_jacobyKey, v);

  // ── Customization ─────────────────────────────────────────
  int get boardSet => _prefs.getInt(_boardSetKey) ?? 1;
  set boardSet(int v) => _prefs.setInt(_boardSetKey, v);

  int get checkerSet => _prefs.getInt(_checkerSetKey) ?? 1;
  set checkerSet(int v) => _prefs.setInt(_checkerSetKey, v);

  int get diceSet => _prefs.getInt(_diceSetKey) ?? 1;
  set diceSet(int v) => _prefs.setInt(_diceSetKey, v);

  // ── Greek Level (0.0 = English only, 1.0 = Fluent) ────
  double get greekLevel => _prefs.getDouble(_greekLevelKey) ?? 0.5;
  set greekLevel(double v) => _prefs.setDouble(_greekLevelKey, v);

  // ── Bot Personality ─────────────────────────────────────
  BotPersonality get botPersonality =>
      BotPersonality.fromStorageKey(_prefs.getString(_personalityKey));
  set botPersonality(BotPersonality v) =>
      _prefs.setString(_personalityKey, v.toStorageKey());

  // ── Tradition ─────────────────────────────────────────
  Tradition get tradition =>
      Tradition.fromStorageKey(_prefs.getString(_traditionKey));
  set tradition(Tradition v) =>
      _prefs.setString(_traditionKey, v.toStorageKey());

  // ── Language Level (0.0 = English only, 1.0 = Fluent) ─
  /// Unified language level — replaces the old Greek-only level.
  /// Falls back to greekLevel if the new key doesn't exist yet (migration).
  double get languageLevel =>
      _prefs.getDouble(_languageLevelKey) ??
      _prefs.getDouble(_greekLevelKey) ??
      0.5;
  set languageLevel(double v) => _prefs.setDouble(_languageLevelKey, v);

  // ── Player Display Name ─────────────────────────────────
  String get playerDisplayName => _prefs.getString(_playerNameKey) ?? '';
  set playerDisplayName(String v) => _prefs.setString(_playerNameKey, v);

  /// Clears all persisted settings and onboarding state.
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

/// Provider that bridges SettingsService to Riverpod.
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService.instance;
});
