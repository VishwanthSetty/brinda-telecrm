import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/settings.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/settings/settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: List.generate(
            6,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SkeletonBox.fill(height: 56),
            ),
          ),
        ),
        error: (e, s) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(settingsNotifierProvider),
        ),
        data: (settings) => _SettingsBody(settings: settings),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final AppSettings settings;
  const _SettingsBody({required this.settings});

  Future<void> _handleError(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.showError(context, 'Failed to save: please retry');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        // SIM Configuration
        SettingsSection(
          title: 'SIM Configuration',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monitor SIM slot',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<int>(
                    segments: simSlotLabels.entries
                        .map((e) => ButtonSegment<int>(
                              value: e.key,
                              label: Text(e.value),
                            ))
                        .toList(),
                    selected: {settings.simSlot},
                    onSelectionChanged: (v) => _handleError(
                      context,
                      () => notifier.updateSimSlot(v.first),
                    ),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.primary;
                        }
                        return null;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.onPrimary;
                        }
                        return AppColors.onBackground;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Recording Rules
        SettingsSection(
          title: 'Recording Rules',
          children: [
            SettingsToggleTile(
              title: 'Enable Recording Upload',
              subtitle: 'Upload OEM call recordings to server',
              value: settings.recordingEnabled,
              onChanged: (v) => _handleError(
                context,
                () => notifier.updateRecordingRules(recordingEnabled: v),
              ),
            ),
            if (settings.recordingEnabled) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recording mode',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    RadioGroup<String>(
                      groupValue: settings.recordingMode,
                      onChanged: (v) => _handleError(
                        context,
                        () => notifier.updateRecordingRules(recordingMode: v),
                      ),
                      child: Column(
                        children: recordingModeLabels.entries
                            .map((e) => RadioListTile<String>(
                                  title: Text(e.value,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  value: e.key,
                                  activeColor: AppColors.primary,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              if (settings.recordingMode == 'whitelist' ||
                  settings.recordingMode == 'blacklist')
                SettingsNavTile(
                  title: settings.recordingMode == 'whitelist'
                      ? 'Whitelist Numbers'
                      : 'Blacklist Numbers',
                  subtitle: '${settings.numberList.length} numbers configured',
                  leadingIcon: Icons.format_list_bulleted,
                  onTap: () => context.go(
                    '/settings/numbers?mode=${settings.recordingMode}',
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direction filter',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SegmentedButton<String>(
                      segments: directionFilterLabels.entries
                          .map((e) => ButtonSegment<String>(
                                value: e.key,
                                label: Text(e.value),
                              ))
                          .toList(),
                      selected: {settings.directionFilter},
                      onSelectionChanged: (v) => _handleError(
                        context,
                        () => notifier.updateRecordingRules(
                            directionFilter: v.first),
                      ),
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          return null;
                        }),
                        foregroundColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.onPrimary;
                          }
                          return AppColors.onBackground;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              SettingsToggleTile(
                title: 'Time-based Filter',
                subtitle: 'Only record during set hours',
                value: settings.timeFilterEnabled,
                onChanged: (v) => _handleError(
                  context,
                  () => notifier.updateRecordingRules(timeFilterEnabled: v),
                ),
              ),
              if (settings.timeFilterEnabled)
                _TimeFilterRow(settings: settings, notifier: notifier),
            ],
          ],
        ),

        // Sync Settings
        SettingsSection(
          title: 'Sync Settings',
          children: [
            SettingsToggleTile(
              title: 'Enable Call Log Sync',
              subtitle: 'Send call metadata to server',
              value: settings.logSyncEnabled,
              onChanged: (v) => _handleError(
                context,
                () => notifier.updateSyncSettings(logSyncEnabled: v),
              ),
            ),
            if (settings.logSyncEnabled) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sync frequency',
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.sm),
                    RadioGroup<String>(
                      groupValue: settings.syncFrequency,
                      onChanged: (v) => _handleError(
                        context,
                        () => notifier.updateSyncSettings(syncFrequency: v),
                      ),
                      child: Column(
                        children: syncFrequencyLabels.entries
                            .map((e) => RadioListTile<String>(
                                  title: Text(e.value,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  value: e.key,
                                  activeColor: AppColors.primary,
                                  contentPadding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              SettingsToggleTile(
                title: 'WiFi Only (Sync)',
                subtitle: 'Sync logs only on WiFi',
                value: settings.wifiOnlySync,
                onChanged: (v) => _handleError(
                  context,
                  () => notifier.updateSyncSettings(wifiOnlySync: v),
                ),
              ),
              SettingsToggleTile(
                title: 'WiFi Only (Upload)',
                subtitle: 'Upload recordings only on WiFi',
                value: settings.wifiOnlyUpload,
                onChanged: (v) => _handleError(
                  context,
                  () => notifier.updateSyncSettings(wifiOnlyUpload: v),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TimeFilterRow extends ConsumerWidget {
  final AppSettings settings;
  final SettingsNotifier notifier;

  const _TimeFilterRow({required this.settings, required this.notifier});

  Future<void> _pickTime(
    BuildContext context,
    bool isStart,
  ) async {
    TimeOfDay initial = TimeOfDay.now();
    final existing = isStart ? settings.timeFilterStart : settings.timeFilterEnd;
    if (existing != null) {
      final parts = existing.split(':');
      if (parts.length == 2) {
        initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !context.mounted) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await notifier.updateRecordingRules(
      timeFilterStart: isStart ? formatted : settings.timeFilterStart,
      timeFilterEnd: isStart ? settings.timeFilterEnd : formatted,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickTime(context, true),
              icon: const Icon(Icons.access_time, size: 16),
              label: Text(
                settings.timeFilterStart ?? 'Start time',
                style: textTheme.bodyMedium,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.divider),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('to'),
          ),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickTime(context, false),
              icon: const Icon(Icons.access_time, size: 16),
              label: Text(
                settings.timeFilterEnd ?? 'End time',
                style: textTheme.bodyMedium,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.divider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
