import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Reusable error state widget for network/loading failures.
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Network-specific error.
  const ErrorStateWidget.offline({
    super.key,
    this.onRetry,
  })  : title = 'No Connection',
        message = 'Check your internet connection and try again.',
        icon = Icons.wifi_off;

  /// Game sync error.
  const ErrorStateWidget.syncError({
    super.key,
    this.onRetry,
  })  : title = 'Sync Error',
        message = 'Could not sync with the game server.',
        icon = Icons.sync_problem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TavliSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: TavliColors.error),
            const SizedBox(height: TavliSpacing.md),
            Text(title, style: theme.textTheme.headlineMedium),
            if (message != null) ...[
              const SizedBox(height: TavliSpacing.xs),
              Text(
                message!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: TavliSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 24),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
