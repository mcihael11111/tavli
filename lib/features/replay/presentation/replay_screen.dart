import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../game/data/models/board_state.dart';
import '../data/game_recording.dart';

/// Screen for replaying a recorded game move-by-move.
class ReplayScreen extends StatefulWidget {
  final GameRecording recording;

  const ReplayScreen({super.key, required this.recording});

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  int _currentTurn = -1; // -1 = initial state
  bool _isPlaying = false;
  Timer? _autoPlayTimer;
  double _playbackSpeed = 1.0;

  BoardState get _currentBoard {
    if (_currentTurn < 0) return widget.recording.initialBoard;
    return widget.recording.turns[_currentTurn].boardAfter;
  }

  int get _totalTurns => widget.recording.turns.length;

  bool get _isAtStart => _currentTurn < 0;
  bool get _isAtEnd => _currentTurn >= _totalTurns - 1;

  RecordedTurn? get _currentTurnData {
    if (_currentTurn < 0 || _currentTurn >= _totalTurns) return null;
    return widget.recording.turns[_currentTurn];
  }

  void _goToStart() {
    _stopAutoPlay();
    setState(() => _currentTurn = -1);
  }

  void _goToEnd() {
    _stopAutoPlay();
    setState(() => _currentTurn = _totalTurns - 1);
  }

  void _stepForward() {
    if (_isAtEnd) {
      _stopAutoPlay();
      return;
    }
    setState(() => _currentTurn++);
  }

  void _stepBackward() {
    if (_isAtStart) return;
    setState(() => _currentTurn--);
  }

  void _toggleAutoPlay() {
    if (_isPlaying) {
      _stopAutoPlay();
    } else {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    if (_isAtEnd) {
      _goToStart();
    }
    setState(() => _isPlaying = true);
    _autoPlayTimer = Timer.periodic(
      Duration(milliseconds: (2000 / _playbackSpeed).round()),
      (_) {
        if (_isAtEnd) {
          _stopAutoPlay();
        } else {
          _stepForward();
        }
      },
    );
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    if (mounted) setState(() => _isPlaying = false);
  }

  void _setSpeed(double speed) {
    _playbackSpeed = speed;
    if (_isPlaying) {
      _stopAutoPlay();
      _startAutoPlay();
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rec = widget.recording;
    final turn = _currentTurnData;

    return GradientScaffold(
      appBar: AppBar(
        title: Text('${rec.player1Name} vs ${rec.player2Name}'),
        actions: [
          if (rec.result != null)
            Padding(
              padding: const EdgeInsets.only(right: TavliSpacing.md),
              child: Center(
                child: Text(
                  rec.result!.winner == 1 ? '${rec.player1Name} won' : '${rec.player2Name} won',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: TavliColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Board visualization
          Expanded(child: _buildBoardView(theme)),

          // Turn info
          _buildTurnInfo(theme, turn),

          // Timeline slider
          _buildTimeline(theme),

          // Playback controls
          _buildControls(theme),

          const SizedBox(height: TavliSpacing.md),
        ],
      ),
    );
  }

  Widget _buildBoardView(ThemeData theme) {
    final board = _currentBoard;
    return Padding(
      padding: const EdgeInsets.all(TavliSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: TavliColors.primary,
          borderRadius: BorderRadius.circular(TavliRadius.lg),
          border: Border.all(color: TavliColors.background),
          boxShadow: TavliShadows.medium,
        ),
        child: Padding(
          padding: const EdgeInsets.all(TavliSpacing.sm),
          child: Column(
            children: [
              // Top row: points 12-23
              Expanded(
                child: Row(
                  children: [
                    for (int i = 12; i < 24; i++)
                      Expanded(child: _buildPoint(i, board, isTop: true)),
                  ],
                ),
              ),
              // Bar and borne off info
              Padding(
                padding: const EdgeInsets.symmetric(vertical: TavliSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusChip('Bar: ${board.bar1}', TavliColors.checkerDark),
                    const SizedBox(width: TavliSpacing.sm),
                    _buildStatusChip('Off: ${board.borneOff1}', TavliColors.checkerDark),
                    const SizedBox(width: TavliSpacing.lg),
                    _buildStatusChip('Bar: ${board.bar2}', TavliColors.checkerLight),
                    const SizedBox(width: TavliSpacing.sm),
                    _buildStatusChip('Off: ${board.borneOff2}', TavliColors.checkerLight),
                  ],
                ),
              ),
              // Bottom row: points 11-0
              Expanded(
                child: Row(
                  children: [
                    for (int i = 11; i >= 0; i--)
                      Expanded(child: _buildPoint(i, board, isTop: false)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoint(int index, BoardState board, {required bool isTop}) {
    final count = board.points[index];
    final isP1 = count > 0;
    final absCount = count.abs();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        mainAxisAlignment: isTop ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isTop) const Spacer(),
          if (absCount > 0)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isP1 ? TavliColors.checkerDark : TavliColors.checkerLight,
                border: Border.all(
                  color: isP1 ? TavliColors.text : TavliColors.primary,
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$absCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isP1 ? TavliColors.light : TavliColors.text,
                  ),
                ),
              ),
            ),
          if (isTop) const Spacer(),
          Text(
            '${index + 1}',
            style: const TextStyle(fontSize: 8, color: TavliColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TavliSpacing.xs,
        vertical: TavliSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(TavliRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }

  Widget _buildTurnInfo(ThemeData theme, RecordedTurn? turn) {
    if (turn == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(TavliSpacing.sm),
          decoration: BoxDecoration(
            color: TavliColors.surface,
            borderRadius: BorderRadius.circular(TavliRadius.md),
          ),
          child: Text(
            'Starting position',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final playerName = turn.player == 1
        ? widget.recording.player1Name
        : widget.recording.player2Name;
    final movesText = turn.moves.isEmpty
        ? 'No moves (forced pass)'
        : turn.moves.map((m) => '${m.fromPoint + 1}→${m.isBearOff ? "off" : "${m.toPoint + 1}"}').join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(TavliSpacing.sm),
        decoration: BoxDecoration(
          color: TavliColors.surface,
          borderRadius: BorderRadius.circular(TavliRadius.md),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: turn.player == 1
                  ? TavliColors.checkerDark
                  : TavliColors.checkerLight,
              child: Text(
                playerName[0],
                style: TextStyle(
                  fontSize: 12,
                  color: turn.player == 1 ? TavliColors.light : TavliColors.text,
                ),
              ),
            ),
            const SizedBox(width: TavliSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$playerName rolled ${turn.die1}-${turn.die2}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    movesText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: TavliColors.light.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TavliSpacing.md,
        vertical: TavliSpacing.xs,
      ),
      child: Row(
        children: [
          Text(
            '${_currentTurn + 1}',
            style: theme.textTheme.bodySmall,
          ),
          Expanded(
            child: Slider(
              value: (_currentTurn + 1).toDouble(),
              min: 0,
              max: _totalTurns.toDouble(),
              divisions: _totalTurns > 0 ? _totalTurns : 1,
              onChanged: (value) {
                _stopAutoPlay();
                setState(() => _currentTurn = value.round() - 1);
              },
              activeColor: TavliColors.primary,
              inactiveColor: TavliColors.primary.withValues(alpha: 0.2),
            ),
          ),
          Text(
            '$_totalTurns',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Speed selector
          _buildSpeedButton(0.5),
          _buildSpeedButton(1.0),
          _buildSpeedButton(2.0),
          const SizedBox(width: TavliSpacing.lg),

          // Playback buttons
          IconButton(
            onPressed: _isAtStart ? null : _goToStart,
            icon: const Icon(Icons.skip_previous),
            color: TavliColors.primary,
          ),
          IconButton(
            onPressed: _isAtStart ? null : _stepBackward,
            icon: const Icon(Icons.chevron_left),
            color: TavliColors.primary,
          ),
          IconButton(
            onPressed: _toggleAutoPlay,
            icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
            iconSize: 48,
            color: TavliColors.primary,
          ),
          IconButton(
            onPressed: _isAtEnd ? null : _stepForward,
            icon: const Icon(Icons.chevron_right),
            color: TavliColors.primary,
          ),
          IconButton(
            onPressed: _isAtEnd ? null : _goToEnd,
            icon: const Icon(Icons.skip_next),
            color: TavliColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedButton(double speed) {
    final isActive = _playbackSpeed == speed;
    return GestureDetector(
      onTap: () => _setSpeed(speed),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: TavliSpacing.xs,
          vertical: TavliSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: isActive ? TavliColors.primary : TavliColors.surface,
          borderRadius: BorderRadius.circular(TavliRadius.sm),
        ),
        child: Text(
          '${speed}x',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: TavliColors.light,
          ),
        ),
      ),
    );
  }
}
