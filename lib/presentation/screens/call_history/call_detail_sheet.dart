import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/call_log.dart';
import '../../../data/services/call_log_service.dart';
import '../../../data/services/recording_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_logs_provider.dart';
import '../../widgets/common/app_snackbar.dart';

class CallDetailSheet extends ConsumerStatefulWidget {
  final String callId;
  const CallDetailSheet({super.key, required this.callId});

  @override
  ConsumerState<CallDetailSheet> createState() => _CallDetailSheetState();
}

class _CallDetailSheetState extends ConsumerState<CallDetailSheet> {
  CallLog? _log;
  bool _loading = true;
  String? _error;

  final _noteCtrl = TextEditingController();
  String? _selectedDisposition;
  bool _saving = false;
  bool _loadingRecording = false;

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLog() async {
    try {
      final log = await CallLogService(ref.read(apiClientProvider))
          .getLog(widget.callId);
      if (mounted) {
        setState(() {
          _log = log;
          _noteCtrl.text = log.note ?? '';
          _selectedDisposition = log.disposition;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    if (_log == null) return;
    setState(() => _saving = true);
    try {
      final updated = await CallLogService(ref.read(apiClientProvider)).updateLog(
        widget.callId,
        CallLogUpdate(
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          disposition: _selectedDisposition,
        ),
      );
      ref.read(callLogsNotifierProvider.notifier).updateLog(updated);
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Saved');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _playRecording() async {
    if (_log?.recordingId == null) return;
    setState(() => _loadingRecording = true);
    try {
      final result = await RecordingService(ref.read(apiClientProvider))
          .getUrl(_log!.recordingId!);
      final uri = Uri.parse(result.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) AppSnackbar.showError(context, 'Cannot open recording');
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Failed to load recording');
    } finally {
      if (mounted) setState(() => _loadingRecording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.sm, 0,
              ),
              child: Row(
                children: [
                  Text('Call Details', style: textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? Center(child: Text(_error!, style: textTheme.bodyMedium))
                      : _buildContent(ctx, scrollCtrl, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollCtrl,
    TextTheme textTheme,
  ) {
    final log = _log!;
    final directionColor = switch (log.direction) {
      'inbound' => AppColors.inbound,
      'outbound' => AppColors.outbound,
      'missed' => AppColors.missed,
      _ => AppColors.rejected,
    };

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Call info card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: directionColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.direction.toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(
                        color: directionColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (log.hasRecording)
                    _RecordingButton(
                      loading: _loadingRecording,
                      onTap: _playRecording,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                icon: Icons.phone,
                label: 'Number',
                value: log.phoneNumber,
              ),
              if (log.contactName != null && log.contactName!.isNotEmpty)
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Contact',
                  value: log.contactName!,
                ),
              _InfoRow(
                icon: Icons.access_time,
                label: 'Time',
                value: DateFormatter.formatDateTime(log.startedAt),
              ),
              _InfoRow(
                icon: Icons.timelapse,
                label: 'Duration',
                value: DurationFormatter.formatLong(log.durationSeconds),
              ),
              _InfoRow(
                icon: Icons.sim_card,
                label: 'SIM',
                value: 'SIM ${log.simSlot + 1}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Disposition picker
        Text('Tag this call', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: dispositionOptions.map((d) {
            final selected = _selectedDisposition == d;
            return ChoiceChip(
              label: Text(d),
              selected: selected,
              onSelected: (_) =>
                  setState(() => _selectedDisposition = selected ? null : d),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? AppColors.onPrimary : AppColors.onBackground,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.divider,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Note input
        Text('Note', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add a note about this call...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Save button
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                  ),
                )
              : const Text('Save'),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 72,
            child: Text(label, style: textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _RecordingButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: const BorderSide(color: AppColors.primaryMid),
        foregroundColor: AppColors.primary,
      ),
      icon: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMid),
            )
          : const Icon(Icons.play_circle_outline, size: 16),
      label: const Text('Play', style: TextStyle(fontSize: 13)),
    );
  }
}
