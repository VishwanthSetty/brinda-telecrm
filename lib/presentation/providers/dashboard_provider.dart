import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard.dart';
import '../../data/services/dashboard_service.dart';
import 'auth_provider.dart';

final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService(ref.read(apiClientProvider)),
);

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) {
  return ref.read(dashboardServiceProvider).getSummary();
});

final dashboardTrendProvider = FutureProvider<TrendResponse>((ref) {
  return ref.read(dashboardServiceProvider).getTrend(days: 7);
});

final recordingStatsProvider = FutureProvider<RecordingStats>((ref) {
  return ref.read(dashboardServiceProvider).getRecordingStats();
});
