import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/services/copy_service.dart';
import '../../../shared/services/settings_service.dart';
import '../../../shared/widgets/content_module.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../ai/difficulty/difficulty_level.dart';
import '../../game/data/models/game_result.dart';

/// A single match history entry.
class MatchRecord {
  final DateTime timestamp;
  final DifficultyLevel? difficulty;
  final String opponentName;
  final bool playerWon;
  final GameResultType resultType;
  final int cubeValue;
  final int playerPips;
  final int opponentPips;
  final String mode;

  const MatchRecord({
    required this.timestamp,
    this.difficulty,
    required this.opponentName,
    required this.playerWon,
    required this.resultType,
    this.cubeValue = 1,
    this.playerPips = 0,
    this.opponentPips = 0,
    this.mode = 'bot',
  });

  int get points {
    final mul = switch (resultType) {
      GameResultType.single => 1,
      GameResultType.gammon => 2,
      GameResultType.backgammon => 3,
    };
    return mul * cubeValue;
  }

  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'diff': difficulty?.name,
        'opp': opponentName,
        'won': playerWon,
        'type': resultType.name,
        'cube': cubeValue,
        'pPips': playerPips,
        'oPips': opponentPips,
        'mode': mode,
      };

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    return MatchRecord(
      timestamp: DateTime.parse(json['ts'] as String),
      difficulty: json['diff'] != null
          ? DifficultyLevel.values.byName(json['diff'] as String)
          : null,
      opponentName: json['opp'] as String,
      playerWon: json['won'] as bool,
      resultType: GameResultType.values.byName(json['type'] as String),
      cubeValue: json['cube'] as int? ?? 1,
      playerPips: json['pPips'] as int? ?? 0,
      opponentPips: json['oPips'] as int? ?? 0,
      mode: json['mode'] as String? ?? 'bot',
    );
  }
}

/// Service to persist match history.
class MatchHistoryService {
  static const _key = 'tavli_match_history';
  static const _maxRecords = 100;

  static Future<List<MatchRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => MatchRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> record(MatchRecord entry) async {
    final records = await load();
    records.insert(0, entry);
    if (records.length > _maxRecords) records.removeLast();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, jsonEncode(records.map((r) => r.toJson()).toList()));
  }
}

/// Match history screen.
class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  List<MatchRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await MatchHistoryService.load();
    if (mounted) setState(() { _records = records; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(title: Text(TavliCopy.matchHistory)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _records.isEmpty
                ? _buildEmpty(theme)
                : _buildList(theme),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 48, color: TavliColors.light.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('No games yet', style: theme.textTheme.headlineMedium?.copyWith(
            color: TavliColors.light,
          )),
          const SizedBox(height: 4),
          Text(
            "Play a game and it'll show up here!",
            style: TextStyle(
              fontSize: 14,
              color: TavliColors.light.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, kToolbarHeight + TavliSpacing.md, 12, 12),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final r = _records[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ContentModule(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: r.playerWon
                  ? TavliColors.success.withValues(alpha: 0.15)
                  : TavliColors.error.withValues(alpha: 0.15),
              child: Icon(
                r.playerWon ? Icons.emoji_events : Icons.close,
                color: r.playerWon ? TavliColors.success : TavliColors.error,
                size: 20,
              ),
            ),
            title: 'vs ${r.opponentName}',
            body: '${_resultLabel(r.resultType)} \u00b7 ${r.points} pts \u00b7 ${_modeLabel(r.mode)}',
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  r.playerWon ? 'WIN' : 'LOSS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: r.playerWon ? TavliColors.success : TavliColors.error,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  _timeAgo(r.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: TavliColors.light.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _resultLabel(GameResultType t) => switch (t) {
        GameResultType.single => 'Single',
        GameResultType.gammon => 'Gammon',
        GameResultType.backgammon => 'Backgammon',
      };

  String _modeLabel(String m) => switch (m) {
        'bot' => 'vs ${SettingsService.instance.botPersonality.displayName}',
        'online' => 'Online',
        'pass-play' => 'Pass & Play',
        _ => m,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
