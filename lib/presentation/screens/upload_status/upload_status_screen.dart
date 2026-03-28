import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/recording.dart';
import '../../../data/services/recording_matcher_service.dart';
import '../../providers/upload_provider.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton_loader.dart';

class UploadStatusScreen extends ConsumerWidget {
  const UploadStatusScreen({super.key});

  Future<void> _runSync(BuildContext context, WidgetRef ref) async {
    ref.read(isScanningProvider.notifier).state = true;
    try {
      final count =
          await ref.read(pendingRecordingsProvider.notifier).runAutoUpload();
      if (!context.mounted) return;
      if (count > 0) {
        AppSnackbar.showSuccess(
          context,
          '$count recording${count == 1 ? '' : 's'} uploaded',
        );
      } else {
        AppSnackbar.showSuccess(context, 'No new recordings found');
      }
    } on RecordingFolderNotFoundException {
      if (!context.mounted) return;
      AppSnackbar.showError(
        context,
        'Recordings folder not found. Check path in Settings.',
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackbar.showError(context, 'Sync failed. Please try again.');
    } finally {
      ref.read(isScanningProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingRecordingsProvider);
    final isScanning = ref.watch(isScanningProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Status'),
        actions: [
          if (isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync Recordings',
              onPressed: () => _runSync(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(pendingRecordingsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(pendingRecordingsProvider.notifier).refresh(),
        child: pendingAsync.when(
          loading: () => ListView(
            children: List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: SkeletonBox.fill(height: 80, radius: 12),
              ),
            ),
          ),
          error: (e, s) => ErrorState(
            message: e.toString(),
            onRetry: () =>
                ref.read(pendingRecordingsProvider.notifier).refresh(),
          ),
          data: (recordings) {
            if (recordings.isEmpty) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 500,
                  child: EmptyState(
                    icon: Icons.cloud_done_outlined,
                    title: 'All recordings uploaded',
                    subtitle: 'No pending uploads at the moment',
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${recordings.length} recording${recordings.length == 1 ? '' : 's'} pending upload',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Pending Uploads', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                ...recordings.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _PendingRecordingTile(recording: r),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                        color: AppColors.primaryMid.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Tap "Sync" to auto-match recordings, or tap "Upload" on each call to pick a file manually.',
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PendingRecordingTile extends ConsumerWidget {
  final PendingRecording recording;
  const _PendingRecordingTile({required this.recording});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final uploadingIds = ref.watch(uploadingIdsProvider);
    final isUploading = uploadingIds.contains(recording.callLogId);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recording.phoneNumber, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _DirectionBadge(direction: recording.direction),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      DurationFormatter.format(recording.durationSeconds),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                Text(
                  DateFormatter.formatDateTime(recording.startedAt),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          isUploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FilledButton.tonal(
                  onPressed: () => _pickAndUpload(context, ref),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Upload'),
                ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'mp4', 'm4a', 'aac', 'wav', 'amr', '3gp', 'ogg'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = result.files.single;
    final success = await ref
        .read(pendingRecordingsProvider.notifier)
        .uploadRecording(
          callLogId: recording.callLogId,
          filePath: file.path!,
          fileName: file.name,
          durationSeconds: recording.durationSeconds,
        );

    if (!context.mounted) return;
    if (success) {
      AppSnackbar.showSuccess(context, 'Recording uploaded successfully');
    } else {
      AppSnackbar.showError(context, 'Upload failed. Please try again.');
    }
  }
}

class _DirectionBadge extends StatelessWidget {
  final String direction;
  const _DirectionBadge({required this.direction});

  @override
  Widget build(BuildContext context) {
    final color = switch (direction) {
      'inbound' => AppColors.inbound,
      'outbound' => AppColors.outbound,
      'missed' => AppColors.missed,
      _ => AppColors.rejected,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        direction[0].toUpperCase() + direction.substring(1),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
