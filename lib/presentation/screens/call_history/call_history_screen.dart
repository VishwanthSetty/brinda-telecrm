import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../providers/call_logs_provider.dart';
import '../../widgets/common/call_list_tile.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton_loader.dart';
import 'call_detail_sheet.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(callLogsNotifierProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    ref.read(callLogFilterProvider.notifier).update(
          (f) => f.copyWith(searchQuery: query),
        );
    ref.read(callLogsNotifierProvider.notifier).refresh();
  }

  void _onFilterChanged(String? direction) {
    ref.read(callLogFilterProvider.notifier).update(
          (f) => direction == null
              ? f.copyWith(clearDirection: true)
              : f.copyWith(direction: direction),
        );
    ref.read(callLogsNotifierProvider.notifier).refresh();
  }

  static const _filters = [
    (label: 'All', value: null),
    (label: 'Inbound', value: 'inbound'),
    (label: 'Outbound', value: 'outbound'),
    (label: 'Missed', value: 'missed'),
  ];

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(callLogsNotifierProvider);
    final filter = ref.watch(callLogFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Call History')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search by number...',
                prefixIcon: Icon(Icons.search, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm,
              ),
              children: _filters.map((f) {
                final selected = filter.direction == f.value;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(f.label),
                    selected: selected,
                    onSelected: (_) => _onFilterChanged(f.value),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.onPrimary : AppColors.onBackground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    checkmarkColor: AppColors.onPrimary,
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: logsAsync.when(
              loading: () => ListView.separated(
                itemCount: 8,
                separatorBuilder: (_, i) => const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) => const ListTileSkeleton(),
              ),
              error: (e, s) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.read(callLogsNotifierProvider.notifier).refresh(),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return EmptyState(
                    icon: Icons.call_outlined,
                    title: 'No calls found',
                    subtitle: filter.direction != null || filter.searchQuery.isNotEmpty
                        ? 'Try adjusting your filters'
                        : 'Call logs will appear here once synced',
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(callLogsNotifierProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    itemCount: logs.length + 1,
                    separatorBuilder: (_, i) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (ctx, i) {
                      if (i == logs.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryMid,
                              ),
                            ),
                          ),
                        );
                      }
                      final log = logs[i];
                      return CallListTile(
                        log: log,
                        onTap: () => _showDetail(ctx, log.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, String callId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CallDetailSheet(callId: callId),
    );
  }
}
