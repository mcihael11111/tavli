import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Turn timer widget for online multiplayer.
///
/// Counts down from [totalSeconds], calls [onTimeout] when expired.
/// Visual: circular progress indicator turning red as time runs out.
class TurnTimer extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback? onTimeout;
  final bool isActive;

  const TurnTimer({
    super.key,
    this.totalSeconds = 30,
    this.onTimeout,
    this.isActive = true,
  });

  @override
  State<TurnTimer> createState() => _TurnTimerState();
}

class _TurnTimerState extends State<TurnTimer> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
    if (widget.isActive) _startTimer();
  }

  @override
  void didUpdateWidget(TurnTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _remaining = widget.totalSeconds;
      _startTimer();
    } else if (!widget.isActive && oldWidget.isActive) {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _timer?.cancel();
          widget.onTimeout?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    final fraction = _remaining / widget.totalSeconds;
    final isUrgent = _remaining <= 10;
    final color = isUrgent
        ? Color.lerp(TavliColors.error, TavliColors.surface, fraction)!
        : TavliColors.surface;

    return Semantics(
      label: '$_remaining seconds remaining',
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: fraction,
              strokeWidth: 3,
              backgroundColor: TavliColors.light.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
            Text(
              '$_remaining',
              style: TextStyle(
                color: TavliColors.light,
                fontSize: isUrgent ? 14 : 12,
                fontWeight: isUrgent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
