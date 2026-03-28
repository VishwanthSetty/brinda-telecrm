import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/call_log.dart';
import '../../data/services/call_log_service.dart';
import 'auth_provider.dart';

final callLogServiceProvider = Provider<CallLogService>(
  (ref) => CallLogService(ref.read(apiClientProvider)),
);

// Active filter state
class CallLogFilter {
  final String? direction; // null = all
  final String searchQuery;

  const CallLogFilter({this.direction, this.searchQuery = ''});

  CallLogFilter copyWith({String? direction, String? searchQuery, bool clearDirection = false}) =>
      CallLogFilter(
        direction: clearDirection ? null : (direction ?? this.direction),
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

final callLogFilterProvider = StateProvider<CallLogFilter>(
  (_) => const CallLogFilter(),
);

// Paginated call logs notifier
class CallLogsNotifier extends AsyncNotifier<List<CallLog>> {
  static const _pageSize = 50;
  int _skip = 0;
  bool _hasMore = true;

  @override
  Future<List<CallLog>> build() async {
    _skip = 0;
    _hasMore = true;
    return _fetch();
  }

  Future<List<CallLog>> _fetch() async {
    final filter = ref.read(callLogFilterProvider);
    final result = await ref.read(callLogServiceProvider).getLogs(
          direction: filter.direction,
          phoneNumber: filter.searchQuery.isEmpty ? null : filter.searchQuery,
          limit: _pageSize,
          skip: _skip,
        );
    _hasMore = result.hasMore;
    return result.data;
  }

  bool get hasMore => _hasMore;

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    _skip += _pageSize;
    final more = await _fetch();
    state = AsyncData([...current, ...more]);
  }

  Future<void> refresh() async {
    _skip = 0;
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  void updateLog(CallLog updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((l) => l.id == updated.id ? updated : l).toList(),
    );
  }
}

final callLogsNotifierProvider =
    AsyncNotifierProvider<CallLogsNotifier, List<CallLog>>(
  CallLogsNotifier.new,
);
