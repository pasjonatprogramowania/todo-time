import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_time/services/platform_channels/accessibility_channel.dart';
import 'package:task_time/services/platform_channels/overlay_channel.dart';
import 'package:task_time/services/platform_channels/usage_stats_channel.dart';
import 'dart:developer' as developer;

// --- State Notifiers for individual permission statuses ---

class PermissionStatusNotifier extends StateNotifier<AsyncValue<bool>> {
  final Future<bool> Function() _checker;
  final Future<bool> Function()? _requester; // Requester is optional for manual navigation
  final String _permissionName;

  PermissionStatusNotifier(this._checker, this._requester, this._permissionName) : super(const AsyncValue.loading()) {
    checkStatus();
  }

  Future<void> checkStatus() async {
    state = const AsyncValue.loading();
    try {
      final bool hasPermission = await _checker();
      developer.log('$_permissionName permission status: $hasPermission', name: 'PermissionProvider');
      state = AsyncValue.data(hasPermission);
    } catch (e, s) {
      developer.log('Error checking $_permissionName permission', name: 'PermissionProvider', error: e, stackTrace: s);
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> requestPermission() async {
    if (_requester == null) {
        developer.log('No requester for $_permissionName, likely manual setting navigation.', name: 'PermissionProvider');
        // For permissions that require manual navigation (like Accessibility),
        // the channel method itself often just opens settings.
        // The checkStatus should be called again after user returns from settings.
        // Or, we can assume the channel's request method handles opening settings.
        // For this example, we assume the channel's request method will try to open settings.
        // Let's make a generic request method that just calls the channel's request.
        // The actual granting is done by the user in system settings.
        // We can't directly get the result of that action here.
        await _checker(); // Re-check status after potential settings change.
        return;
    }
    try {
      developer.log('Requesting $_permissionName permission.', name: 'PermissionProvider');
      await _requester!(); // This will open settings
      // After returning from settings, we should re-check the status.
      // This can be done via lifecycle events (WidgetsBindingObserver) on the page,
      // or by simply calling checkStatus again.
      // For simplicity, we'll let the UI trigger a refresh or the user manually re-checks.
      // Or, better, call checkStatus after a short delay or when app resumes.
      await Future.delayed(const Duration(milliseconds: 500)); // Give user time to interact with settings
      await checkStatus();
    } catch (e, s) {
       developer.log('Error requesting $_permissionName permission: $e', name: 'PermissionProvider', error: e, stackTrace: s);
       state = AsyncValue.error('Failed to request permission: $e', s);
    }
  }
}

// --- Providers for each permission ---

final usageStatsPermissionProvider = StateNotifierProvider<PermissionStatusNotifier, AsyncValue<bool>>((ref) {
  return PermissionStatusNotifier(
    UsageStatsChannel.hasPermission,
    UsageStatsChannel.requestPermission,
    'Usage Stats'
  );
});

final overlayPermissionProvider = StateNotifierProvider<PermissionStatusNotifier, AsyncValue<bool>>((ref) {
  return PermissionStatusNotifier(
    OverlayChannel.hasPermission,
    OverlayChannel.requestPermission,
    'Overlay'
  );
});

final accessibilityServiceEnabledProvider = StateNotifierProvider<PermissionStatusNotifier, AsyncValue<bool>>((ref) {
  return PermissionStatusNotifier(
    AccessibilityChannel.isServiceEnabled,
    AccessibilityChannel.requestPermission, // This opens settings
    'Accessibility Service'
  );
});
