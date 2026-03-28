import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../providers/upload_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton_loader.dart';

class UploadStatusScreen extends ConsumerWidget {
  const UploadStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingRecordingsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Status'),
        actions: [
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
                // Summary strip
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

                // Section header
                Text('Pending Uploads', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),

                // List
                ...recordings.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
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
                          // Direction icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: AppColors.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.phoneNumber,
                                  style: textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    _DirectionBadge(direction: r.direction),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      DurationFormatter.format(
                                          r.durationSeconds),
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                Text(
                                  DateFormatter.formatDateTime(r.startedAt),
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),

                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'Pending',
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Note about auto-upload
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
                          'Recordings upload automatically when the background service is active and connected to the network.',
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
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
