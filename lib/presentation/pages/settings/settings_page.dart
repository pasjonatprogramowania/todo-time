import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_time/presentation/providers/permission_providers.dart';
import 'package:task_time/presentation/providers/debug_providers.dart';
import 'package:task_time/services/platform_channels/overlay_channel.dart';
import 'package:task_time/services/platform_channels/background_service_channel.dart'; // Import BackgroundServiceChannel
import 'dart:developer' as developer;

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> with WidgetsBindingObserver {

  String _backgroundServiceStatus = "Service status unknown";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshAllPermissions();
    // TODO: Add a way to get initial background service status if needed
  }

  void _refreshAllPermissions() {
      ref.read(usageStatsPermissionProvider.notifier).checkStatus();
      ref.read(overlayPermissionProvider.notifier).checkStatus();
      ref.read(accessibilityServiceEnabledProvider.notifier).checkStatus();
      developer.log("Refreshed all permission statuses.", name: "SettingsPage");
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      developer.log("App resumed, refreshing permission statuses.", name: "SettingsPage");
      _refreshAllPermissions();
      // TODO: Refresh background service status if possible
    }
  }

  Widget _buildPermissionTile({
    required String title,
    required String description,
    required AsyncValue<bool> status,
    required VoidCallback onRequest,
    required VoidCallback onRefresh,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          status.when(
            data: (granted) => Text(
              granted ? 'Status: Granted' : 'Status: Not Granted',
              style: TextStyle(color: granted ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
            loading: () => const Row(children: [Text('Status: Checking...'), SizedBox(width: 10), SizedBox(height:10, width:10, child: CircularProgressIndicator(strokeWidth: 2))]),
            error: (err, stack) => Text('Status: Error', style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: status.maybeWhen(
        data: (granted) => granted
            ? IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh, tooltip: "Refresh Status")
            : ElevatedButton(onPressed: onRequest, child: const Text('Grant')),
        orElse: () => IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh, tooltip: "Refresh Status"),
      ),
      onTap: status.maybeWhen(
        data: (granted) => granted ? null : onRequest,
        orElse: () => onRequest,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final usageStatsPermission = ref.watch(usageStatsPermissionProvider);
    final overlayPermission = ref.watch(overlayPermissionProvider);
    final accessibilityStatus = ref.watch(accessibilityServiceEnabledProvider);
    final usageStatsDebugState = ref.watch(usageStatsDebugProvider);
    final foregroundAppAsyncValue = ref.watch(foregroundAppStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllPermissions,
            tooltip: "Refresh all permissions",
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: <Widget>[
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(Theme.of(context).brightness == Brightness.dark ? 'Dark Mode' : 'Light Mode'),
            leading: const Icon(Icons.palette),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme switching (not implemented yet)')),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text("App Permissions", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          _buildPermissionTile(
            title: 'Usage Stats Access',
            description: 'Allows TaskTime to monitor app usage to manage screen time.',
            status: usageStatsPermission,
            onRequest: () => ref.read(usageStatsPermissionProvider.notifier).requestPermission(),
            onRefresh: () => ref.read(usageStatsPermissionProvider.notifier).checkStatus(),
          ),
          _buildPermissionTile(
            title: 'Display Over Other Apps',
            description: 'Needed to show the lock screen over blocked applications.',
            status: overlayPermission,
            onRequest: () => ref.read(overlayPermissionProvider.notifier).requestPermission(),
            onRefresh: () => ref.read(overlayPermissionProvider.notifier).checkStatus(),
          ),
          _buildPermissionTile(
            title: 'Accessibility Service',
            description: 'Crucial for identifying foreground apps/websites for blocking. Please enable TaskTime in the list.',
            status: accessibilityStatus,
            onRequest: () => ref.read(accessibilityServiceEnabledProvider.notifier).requestPermission(),
            onRefresh: () => ref.read(accessibilityServiceEnabledProvider.notifier).checkStatus(),
          ),
          const Divider(),
          ListTile(
            title: const Text('Block Schedule'),
            leading: const Icon(Icons.schedule),
            onTap: () {
              // Navigate to BlockSchedulePage
              GoRouter.of(context).pushNamed('block_schedule');
            },
          ),
          ListTile(
            title: const Text('Manage Blocked List'),
            leading: const Icon(Icons.block),
            onTap: () {
              // Navigate to ManageBlockedListPage
              GoRouter.of(context).pushNamed('manage_blocked_list');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Notifications'),
            leading: const Icon(Icons.notifications),
            onTap: () {
              // TODO: Consider navigating to app's system notification settings
              // For now, just a placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings (not implemented yet)')),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text("Debug Options", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('Fetch Daily Usage Stats'),
            subtitle: const Text('Tap to fetch and display today\'s app usage stats below.'),
            leading: const Icon(Icons.bar_chart),
            onTap: () {
              if (ref.read(usageStatsPermissionProvider).asData?.value == true) {
                 ref.read(usageStatsDebugProvider.notifier).fetchDailyStats();
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Usage Stats permission not granted. Please grant it first.')),
                 );
              }
            },
          ),
          if (usageStatsDebugState.isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            )),
          if (usageStatsDebugState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Error: ${usageStatsDebugState.error}', style: const TextStyle(color: Colors.red)),
            ),
          if (usageStatsDebugState.stats != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Usage Stats (${usageStatsDebugState.stats!.length} apps):', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: usageStatsDebugState.stats!.entries.map((entry) {
                        final packageName = entry.key;
                        final duration = entry.value;
                        return ListTile(
                          dense: true,
                          title: Text(packageName, style: const TextStyle(fontSize: 12)),
                          trailing: Text('${duration.inMinutes} min ${duration.inSeconds.remainder(60)}s', style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
              child: Text("Live Foreground App:", style: Theme.of(context).textTheme.titleSmall),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Consumer(
                builder: (context, ref, child) {
                  final fgAppAsync = ref.watch(foregroundAppStreamProvider);
                  return fgAppAsync.when(
                    data: (packageName) => Text(
                        packageName.isEmpty ? "No app detected / Stream idle" : packageName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    loading: () => const Text("Listening for foreground app...",
                        style: TextStyle(fontStyle: FontStyle.italic)),
                    error: (err, stack) => Text('Error: ${err.toString()}',
                        style: const TextStyle(color: Colors.red)),
                  );
                },
              ),
            ),
            const Divider(),
             ListTile(
              title: const Text('Test Lock Screen Overlay'),
              subtitle: const Text('Tap to show the native lock screen.'),
              leading: const Icon(Icons.visibility_on_outlined),
              onTap: () async {
                 if (ref.read(overlayPermissionProvider).asData?.value == true) {
                    developer.log("Attempting to show overlay from debug.", name: "SettingsPage");
                    final success = await OverlayChannel.showOverlay();
                    developer.log("Show overlay call result: $success", name: "SettingsPage");
                 } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Overlay permission not granted. Please grant it first.')),
                    );
                 }
              },
            ),
             ListTile(
              title: const Text('Test Hide Lock Screen'),
              subtitle: const Text('Tap to attempt hiding the native lock screen.'),
              leading: const Icon(Icons.visibility_off_outlined),
              onTap: () async {
                developer.log("Attempting to hide overlay from debug button.", name: "SettingsPage");
                await OverlayChannel.hideOverlay();
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Start Background Service'),
              leading: const Icon(Icons.play_circle_outline),
              onTap: () async {
                final result = await BackgroundServiceChannel.startService();
                setState(() {
                  _backgroundServiceStatus = result ?? "Start request sent, no specific result.";
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Start Service: $result')));
              },
            ),
            ListTile(
              title: const Text('Stop Background Service'),
              leading: const Icon(Icons.stop_circle_outlined),
              onTap: () async {
                final result = await BackgroundServiceChannel.stopService();
                 setState(() {
                  _backgroundServiceStatus = result ?? "Stop request sent, no specific result.";
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stop Service: $result')));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text("Background Service Status: $_backgroundServiceStatus", style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
