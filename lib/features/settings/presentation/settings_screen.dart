import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/services/settings_service.dart';
import '../../../shared/services/app_info.dart';
import '../../ai/personality/bot_personality.dart';

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
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
          children: [
            const SizedBox(height: TavliSpacing.xxl),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 32,
                fontFamily: TavliTheme.serifFamily,
                fontWeight: FontWeight.w400,
                color: TavliColors.text,
                letterSpacing: -0.64,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TavliSpacing.lg),
            const _SectionHeader('Game Settings'),
          SwitchListTile(
            title: const Text('Show Pip Count'),
            subtitle: const Text('Display remaining pip count during games'),
            value: ref.watch(showPipCountProvider),
            onChanged: (v) => _update(ref, showPipCountProvider, v,
                (s, val) => s.showPipCount = val),
          ),
          SwitchListTile(
            title: const Text('Move Confirmation'),
            subtitle: const Text('Require tap to confirm each move'),
            value: ref.watch(moveConfirmationProvider),
            onChanged: (v) => _update(ref, moveConfirmationProvider, v,
                (s, val) => s.moveConfirmation = val),
          ),
          const Divider(),

          const _SectionHeader('Optional Rules'),
          SwitchListTile(
            title: const Text('Automatic Doubles'),
            subtitle: const Text('Matching first rolls double the stakes'),
            value: ref.watch(autoDoublesProvider),
            onChanged: (v) => _update(ref, autoDoublesProvider, v,
                (s, val) => s.autoDoubles = val),
          ),
          SwitchListTile(
            title: const Text('Beavers'),
            subtitle: const Text('Immediate redouble after being doubled'),
            value: ref.watch(beaversProvider),
            onChanged: (v) => _update(ref, beaversProvider, v,
                (s, val) => s.beavers = val),
          ),
          SwitchListTile(
            title: const Text('Jacoby Rule'),
            subtitle: const Text('Gammons only count if cube was offered'),
            value: ref.watch(jacobyRuleProvider),
            onChanged: (v) => _update(ref, jacobyRuleProvider, v,
                (s, val) => s.jacobyRule = val),
          ),
          const Divider(),

          const _SectionHeader('Bot Personality'),
          ListTile(
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
            title: Text(ref.watch(botPersonalityProvider).displayName),
            subtitle: Text(ref.watch(botPersonalityProvider).subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPersonalityPicker(context, ref),
          ),
          const Divider(),

          const _SectionHeader('Audio'),
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
            title: const Text('Bot Language'),
            subtitle: Text(_languageLabel(ref.watch(mikhailLanguageProvider))),
            trailing: DropdownButton<String>(
              value: ref.watch(mikhailLanguageProvider),
              underline: const SizedBox.shrink(),
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
          const Divider(),

          const _SectionHeader('Display'),
          ListTile(
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
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
          const Divider(),

          const _SectionHeader('About'),
          ListTile(
            title: const Text('Version'),
            trailing: Text(AppInfo.fullVersion),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () {},
          ),
          // Extra padding for bottom nav gradient.
          const SizedBox(height: 140),
        ],
      ),
      ),
    );
  }

  String _languageLabel(String code) => switch (code) {
        'greek' => 'Speaks only Greek',
        'english' => 'Speaks only English',
        _ => 'Mix of Greek and English',
      };

  void _showPersonalityPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(botPersonalityProvider);
    showModalBottomSheet<void>(
      context: context,
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
            for (final p in BotPersonality.values)
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: TavliColors.light,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
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
      title: Text(label),
      subtitle: Slider(value: value, onChanged: onChanged),
      trailing: Text('${(value * 100).round()}%'),
    );
  }
}
