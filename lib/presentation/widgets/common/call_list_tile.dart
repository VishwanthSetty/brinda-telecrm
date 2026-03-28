import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/call_log.dart';

class CallListTile extends StatelessWidget {
  final CallLog log;
  final VoidCallback? onTap;

  const CallListTile({super.key, required this.log, this.onTap});

  IconData get _directionIcon {
    return switch (log.direction) {
      'inbound' => Icons.call_received,
      'outbound' => Icons.call_made,
      'missed' => Icons.call_missed,
      _ => Icons.call_end,
    };
  }

  Color get _directionColor {
    return switch (log.direction) {
      'inbound' => AppColors.inbound,
      'outbound' => AppColors.outbound,
      'missed' => AppColors.missed,
      _ => AppColors.rejected,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayName = log.contactName?.isNotEmpty == true
        ? log.contactName!
        : log.phoneNumber;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Direction icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _directionColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_directionIcon, color: _directionColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (log.contactName != null && log.contactName!.isNotEmpty)
                    Text(
                      log.phoneNumber,
                      style: textTheme.bodySmall,
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        DurationFormatter.format(log.durationSeconds),
                        style: textTheme.bodySmall,
                      ),
                      if (log.disposition != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _DispositionChip(label: log.disposition!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Right: time + recording icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormatter.formatTime(log.startedAt),
                  style: textTheme.bodySmall,
                ),
                Text(
                  DateFormatter.formatShortDate(log.startedAt),
                  style: textTheme.bodySmall,
                ),
                if (log.hasRecording)
                  const Icon(
                    Icons.mic,
                    size: 14,
                    color: AppColors.primaryMid,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DispositionChip extends StatelessWidget {
  final String label;
  const _DispositionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primaryMid.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 10,
              color: AppColors.primary,
            ),
      ),
    );
  }
}
