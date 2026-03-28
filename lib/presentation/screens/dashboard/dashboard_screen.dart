import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/dashboard/trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final trendAsync = ref.watch(dashboardTrendProvider);
    final statsAsync = ref.watch(recordingStatsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(dashboardTrendProvider);
              ref.invalidate(recordingStatsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(dashboardTrendProvider);
          ref.invalidate(recordingStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          children: [
            // Service status badge
            const _ServiceStatusBadge(isRunning: true),
            const SizedBox(height: AppSpacing.lg),

            // Today's summary
            Text("Today's Calls", style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            summaryAsync.when(
              loading: () => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.4,
                children: List.generate(4, (_) => const StatCardSkeleton()),
              ),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(dashboardSummaryProvider),
              ),
              data: (summary) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.4,
                children: [
                  StatCard(
                    label: 'Total Calls',
                    value: '${summary.total}',
                    icon: Icons.call,
                    iconColor: AppColors.primary,
                  ),
                  StatCard(
                    label: 'Inbound',
                    value: '${summary.inbound}',
                    icon: Icons.call_received,
                    iconColor: AppColors.inbound,
                  ),
                  StatCard(
                    label: 'Outbound',
                    value: '${summary.outbound}',
                    icon: Icons.call_made,
                    iconColor: AppColors.outbound,
                  ),
                  StatCard(
                    label: 'Missed',
                    value: '${summary.missed}',
                    icon: Icons.call_missed,
                    iconColor: AppColors.missed,
                  ),
                ],
              ),
            ),

            // Avg duration strip
            summaryAsync.whenData((summary) {
              if (summary.total == 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Avg duration: ${DurationFormatter.format(summary.avgDurationSeconds.round())}',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    const Icon(Icons.timelapse,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Total: ${DurationFormatter.formatLong(summary.totalDurationSeconds)}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }).valueOrNull ?? const SizedBox(),

            const SizedBox(height: AppSpacing.xl),

            // 7-day trend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('7-Day Trend', style: textTheme.titleLarge),
                Text('calls / day',
                    style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.divider),
              ),
              child: trendAsync.when(
                loading: () => const SkeletonBox.fill(height: 160),
                error: (e, s) => SizedBox(
                  height: 160,
                  child: Center(
                    child: ErrorState(
                      message: 'Failed to load trend',
                      onRetry: () => ref.invalidate(dashboardTrendProvider),
                    ),
                  ),
                ),
                data: (trend) => TrendChart(data: trend.data),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recording stats strip
            statsAsync.when(
              loading: () => const SkeletonBox.fill(height: 56),
              error: (e, s) => const SizedBox(),
              data: (stats) => Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${stats.totalRecordings} recordings',
                      style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    const Icon(Icons.storage,
                        color: AppColors.primaryMid, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      DurationFormatter.formatMb(stats.totalSizeMb),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _ServiceStatusBadge extends StatelessWidget {
  // Wire to foreground service state when background service is implemented
  final bool isRunning;
  const _ServiceStatusBadge({required this.isRunning});

  @override
  Widget build(BuildContext context) {
    final color = isRunning ? AppColors.success : AppColors.error;
    final label = isRunning ? 'Service Running' : 'Service Stopped';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
