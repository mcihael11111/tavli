import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/tradition.dart';
import '../../../shared/services/copy_service.dart';
import '../../../shared/services/settings_service.dart';
import '../../../shared/services/app_info.dart';
import '../../../shared/widgets/content_module.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../ai/personality/bot_personality.dart';
import '../../auth/presentation/auth_provider.dart';

// ── Providers that read initial values from persisted settings ────────

final themeProvider = StateProvider<ThemeMode>((ref) {
  return SettingsService.instance.themeMode;
});
final musicVolumeProvider = StateProvider<double>((ref) {
  return SettingsService.instance.musicVolume;
});
final sfxVolumeProvider = StateProvider<double>((ref) {
  return SettingsService.instance.sfxVolume;
});
final voiceVolumeProvider = StateProvider<double>((ref) {
  return SettingsService.instance.voiceVolume;
});
final mikhailLanguageProvider = StateProvider<String>((ref) {
  return SettingsService.instance.mikhailLanguage;
});
final botPersonalityProvider = StateProvider<BotPersonality>((ref) {
  return SettingsService.instance.botPersonality;
});
final showPipCountProvider = StateProvider<bool>((ref) {
  return SettingsService.instance.showPipCount;
});
final moveConfirmationProvider = StateProvider<bool>((ref) {
  return SettingsService.instance.moveConfirmation;
});
final autoDoublesProvider = StateProvider<bool>((ref) {
  return SettingsService.instance.autoDoubles;
});
final beaversProvider = StateProvider<bool>((ref) {
  return SettingsService.instance.beavers;
});
final jacobyRuleProvider = StateProvider<bool>((ref) {
  return SettingsService.instance.jacobyRule;
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _update<T>(WidgetRef ref, StateProvider<T> provider, T value,
      void Function(SettingsService, T) persist) {
    ref.read(provider.notifier).state = value;
    persist(SettingsService.instance, value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientScaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
          children: [
            const SizedBox(height: TavliSpacing.xxl),
            Text(
              TavliCopy.settings,
              style: TextStyle(
                fontSize: 32,
                fontFamily: TavliTheme.serifFamily,
                fontWeight: FontWeight.w400,
                color: TavliColors.light,
                letterSpacing: -0.64,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TavliSpacing.lg),

            // ── Tradition ──────────────────────────
            ContentModule(
              icon: Icons.flag_outlined,
              title: 'Tradition',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  SettingsService.instance.tradition.flagEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(SettingsService.instance.tradition.displayName,
                    style: const TextStyle(color: TavliColors.light)),
                subtitle: Text(SettingsService.instance.tradition.regionLabel,
                    style: TextStyle(color: TavliColors.light.withValues(alpha: 0.7))),
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light),
                onTap: () => _showTraditionPicker(context, ref),
              ),
            ),
            const SizedBox(height: TavliSpacing.sm),

            // ── Game Settings ──────────────────────
            ContentModule(
              icon: Icons.tune,
              title: 'Game Settings',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Pip Count',
                        style: TextStyle(color: TavliColors.light)),
                    subtitle: Text('Display remaining pip count during games',
                        style: TextStyle(color: TavliColors.light.withValues(alpha: 0.7))),
                    value: ref.watch(showPipCountProvider),
                    onChanged: (v) => _update(ref, showPipCountProvider, v,
                        (s, val) => s.showPipCount = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Move Confirmation',
                        style: TextStyle(color: TavliColors.light)),
                    subtitle: Text('Require tap to confirm each move',
                        style: TextStyle(color: TavliColors.light.withValues(alpha: 0.7))),
                    value: ref.watch(moveConfirmationProvider),
                    onChanged: (v) => _update(ref, moveConfirmationProvider, v,
                        (s, val) => s.moveConfirmation = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TavliSpacing.sm),

            // ── Optional Rules ─────────────────────
            ContentModule(
              icon: Icons.rule,
              title: 'Optional Rules',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Automatic Doubles',
                        style: TextStyle(color: TavliColors.light)),
                    subtitle: Text('Matching first rolls double the stakes',
                        style: TextStyle(color: TavliColors.light.withValues(alpha: 0.7))),
                    value: ref.watch(autoDoublesProvider),
                    onChanged: (v) => _update(ref, autoDoublesProvider, v,
                        (s, val) => s.autoDoubles = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Beavers',
                        style: TextStyle(color: TavliColors.light)),
                    subtitle: Text('Immediate redouble after being doubled',
                        style: TextStyle(color: TavliColors.light.withValues(alpha: 0.7))),
                    value: ref.watch(beaversProvider),
                    onChanged: (v) => _update(ref, beaversProvider, v,
                        (s, val) => s.beavers = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Jacoby Rule',
                        style: TextStyle(color: TavliColors.light)),
                    subtitle: Text('Gammons only count if cube was offered',
                        style: TextStyle(color: TavliColors.light.withValues(alpha: 0.7))),
                    value: ref.watch(jacobyRuleProvider),
                    onChanged: (v) => _update(ref, jacobyRuleProvider, v,
                        (s, val) => s.jacobyRule = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TavliSpacing.sm),

            // ── Bot Personality ─────────────────────
            ContentModule(
              icon: Icons.smart_toy_outlined,
              title: 'Bot Personality',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: TavliColors.surface,
                  child: Text(
                    ref.watch(botPersonalityProvider).avatarInitial,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: TavliColors.primary,
                    ),
                  ),
                ),
                title: Text(ref.watch(botPersonalityProvider).displayName,
                    style: const TextStyle(color: TavliColors.light)),
                subtitle: Text(ref.watch(botPersonalityProvider).subtitle,
                    style: TextStyle(color: TavliColors.light.withValues(alpha: 0.7))),
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light),
                onTap: () => _showPersonalityPicker(context, ref),
              ),
            ),
            const SizedBox(height: TavliSpacing.sm),

            // ── Audio ───────────────────────────────
            ContentModule(
              icon: Icons.volume_up,
              title: 'Audio',
              child: Column(
                children: [
                  _VolumeSlider(
                    label: 'Music',
                    value: ref.watch(musicVolumeProvider),
                    onChanged: (v) => _update(ref, musicVolumeProvider, v,
                        (s, val) => s.musicVolume = val),
                  ),
                  _VolumeSlider(
                    label: 'Sound Effects',
                    value: ref.watch(sfxVolumeProvider),
                    onChanged: (v) => _update(ref, sfxVolumeProvider, v,
                        (s, val) => s.sfxVolume = val),
                  ),
                  _VolumeSlider(
                    label: 'Bot Voice',
                    value: ref.watch(voiceVolumeProvider),
                    onChanged: (v) => _update(ref, voiceVolumeProvider, v,
                        (s, val) => s.voiceVolume = val),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bot Language',
                        style: TextStyle(color: TavliColors.light)),
                    subtitle: Text(_languageLabel(ref.watch(mikhailLanguageProvider)),
                        style: TextStyle(color: TavliColors.light.withValues(alpha: 0.7))),
                    trailing: DropdownButton<String>(
                      value: ref.watch(mikhailLanguageProvider),
                      underline: const SizedBox.shrink(),
                      dropdownColor: TavliColors.primary,
                      style: const TextStyle(color: TavliColors.light),
                      items: const [
                        DropdownMenuItem(value: 'greek', child: Text('Greek')),
                        DropdownMenuItem(value: 'english', child: Text('English')),
                        DropdownMenuItem(value: 'mix', child: Text('Mix (Default)')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          _update(ref, mikhailLanguageProvider, v,
                              (s, val) => s.mikhailLanguage = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TavliSpacing.sm),

            // ── Display ─────────────────────────────
            ContentModule(
              icon: Icons.palette_outlined,
              title: 'Display',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme',
                      style: TextStyle(color: TavliColors.light, fontSize: 16)),
                  const SizedBox(height: TavliSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, label: Text('Day')),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Night')),
                        ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                      ],
                      selected: {ref.watch(themeProvider)},
                      onSelectionChanged: (v) => _update(ref, themeProvider, v.first,
                          (s, val) => s.themeMode = val),
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TavliSpacing.sm),

            // ── About ───────────────────────────────
            ContentModule(
              icon: Icons.info_outline,
              title: 'About',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Version',
                        style: TextStyle(color: TavliColors.light)),
                    trailing: Text(AppInfo.fullVersion,
                        style: TextStyle(color: TavliColors.light.withValues(alpha: 0.7))),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Privacy Policy',
                        style: TextStyle(color: TavliColors.light)),
                    trailing: const Icon(Icons.open_in_new, size: 18, color: TavliColors.light),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: TavliSpacing.sm),

            // ── Account ─────────────────────────────
            ContentModule(
              icon: Icons.account_circle_outlined,
              title: 'Account',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: TavliColors.light),
                    title: const Text('Sign Out',
                        style: TextStyle(color: TavliColors.light)),
                    subtitle: Text('Sign out of your account',
                        style: TextStyle(
                            color: TavliColors.light.withValues(alpha: 0.7))),
                    onTap: () => _confirmSignOut(context, ref),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.refresh, color: TavliColors.light),
                    title: const Text('Reset Onboarding',
                        style: TextStyle(color: TavliColors.light)),
                    subtitle: Text('Restart the welcome flow',
                        style: TextStyle(
                            color: TavliColors.light.withValues(alpha: 0.7))),
                    onTap: () => _confirmResetOnboarding(context),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.delete_forever, color: TavliColors.error),
                    title: const Text('Delete Account',
                        style: TextStyle(color: TavliColors.error)),
                    subtitle: Text('Permanently delete all your data',
                        style: TextStyle(
                            color: TavliColors.error.withValues(alpha: 0.7))),
                    onTap: () => _confirmDeleteAccount(context, ref),
                  ),
                ],
              ),
            ),

            // Extra padding for bottom nav gradient.
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TavliColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TavliSpacing.md),
        ),
        title: Text(title,
            style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                  color: TavliColors.text,
                )),
        content: Text(body,
            style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                  color: TavliColors.text,
                )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: TavliColors.primary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  isDestructive ? TavliColors.error : TavliColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: const TextStyle(color: TavliColors.light)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Sign Out',
      body: "Sign out? You'll need to sign in again to play online.",
      confirmLabel: 'Sign Out',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) context.go('/sign-in');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $e')),
        );
      }
    }
  }

  Future<void> _confirmResetOnboarding(BuildContext context) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Reset Onboarding',
      body: 'Reset onboarding? This will restart the welcome flow.',
      confirmLabel: 'Reset',
    );
    if (!confirmed || !context.mounted) return;

    await SettingsService.instance.clearAll();
    if (context.mounted) context.go('/onboarding');
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Delete Account',
      body: "Delete account? This removes all your data and can't be undone.",
      confirmLabel: 'Delete Account',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      // Delete Firestore profile if user exists.
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('players')
            .doc(user.uid)
            .delete();
      }

      // Delete Firebase Auth account.
      await ref.read(authServiceProvider).deleteAccount();

      // Clear all local data.
      await SettingsService.instance.clearAll();

      if (context.mounted) context.go('/onboarding');
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please sign in again before deleting your account.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: ${e.message}')),
        );
      }
    }
  }

  String _languageLabel(String code) => switch (code) {
        'greek' => 'Speaks only Greek',
        'english' => 'Speaks only English',
        _ => 'Mix of Greek and English',
      };

  void _showTraditionPicker(BuildContext context, WidgetRef ref) {
    final current = SettingsService.instance.tradition;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Choose Your Tradition',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            for (final t in Tradition.values)
              ListTile(
                leading: Text(t.flagEmoji, style: const TextStyle(fontSize: 28)),
                title: Text('${t.displayName} — ${t.nativeName}'),
                subtitle: Text('${t.regionLabel} · ${t.variants.length} games'),
                trailing: t == current
                    ? const Icon(Icons.check_circle, color: TavliColors.primary)
                    : null,
                onTap: () {
                  SettingsService.instance.tradition = t;
                  final newDefault = BotPersonality.defaultFor(t);
                  _update(ref, botPersonalityProvider, newDefault,
                      (s, val) => s.botPersonality = val);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPersonalityPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(botPersonalityProvider);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Choose Your Opponent',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            for (final p in BotPersonality.forTradition(
                SettingsService.instance.tradition))
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: TavliColors.surface,
                  child: Text(
                    p.avatarInitial,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: TavliColors.primary,
                    ),
                  ),
                ),
                title: Text(p.displayName),
                subtitle: Text(p.subtitle),
                trailing: p == current
                    ? const Icon(Icons.check_circle,
                        color: TavliColors.primary)
                    : null,
                onTap: () {
                  _update(ref, botPersonalityProvider, p,
                      (s, val) => s.botPersonality = val);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: TavliColors.light)),
      subtitle: Slider(value: value, onChanged: onChanged),
      trailing: Text('${(value * 100).round()}%',
          style: TextStyle(color: TavliColors.light.withValues(alpha: 0.7))),
    );
  }
}
