import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/recording_matcher_service.dart';
import '../../providers/call_sync_provider.dart';
import '../../providers/upload_provider.dart';
import '../../widgets/common/app_snackbar.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  static const _tabs = [
    (path: '/', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    (path: '/history', icon: Icons.call_outlined, activeIcon: Icons.call, label: 'History'),
    (path: '/settings', icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
    (path: '/uploads', icon: Icons.cloud_upload_outlined, activeIcon: Icons.cloud_upload, label: 'Uploads'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial sync on shell load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(callSyncProvider);
      _runAutoUpload();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-sync every time the app comes back to foreground (e.g. after a call)
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(callSyncProvider);
    }
  }

  Future<void> _runAutoUpload() async {
    ref.read(isScanningProvider.notifier).state = true;
    try {
      final count =
          await ref.read(pendingRecordingsProvider.notifier).runAutoUpload();
      if (mounted && count > 0) {
        AppSnackbar.showSuccess(
          context,
          '$count recording${count == 1 ? '' : 's'} uploaded automatically',
        );
      }
    } on RecordingFolderNotFoundException catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'Recordings folder not found. Check path in Settings.',
        );
      }
      // ignore: avoid_print
      print('[AutoUpload] $e');
    } catch (e) {
      // Network or permission errors — silent on launch to avoid spamming
      // ignore: avoid_print
      print('[AutoUpload] Error: $e');
    } finally {
      if (mounted) ref.read(isScanningProvider.notifier).state = false;
    }
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/settings')) return 2;
    if (location.startsWith('/uploads')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Watch so the provider actually executes when invalidated on resume
    ref.watch(callSyncProvider);

    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => context.go(_tabs[i].path),
          destinations: _tabs
              .map(
                (t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
