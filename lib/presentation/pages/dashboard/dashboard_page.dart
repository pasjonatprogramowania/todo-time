import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/presentation/providers/task_usecase_providers.dart';
import 'package:task_time/presentation/providers/screen_time_provider.dart';
import 'package:task_time/presentation/providers/dashboard_providers.dart';
import 'package:task_time/presentation/widgets/task_list_tile.dart';
import 'package:task_time/presentation/widgets/eisenhower_matrix_view.dart'; // Import the new view
import 'dart:developer' as developer;

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    developer.log("DashboardPage initState: Adding WidgetsBindingObserver", name: "DashboardPage");
    // Initial refresh or sync when widget is created and providers are available
    Future.microtask(() {
        developer.log("DashboardPage initState: microtask calling refreshFromSource", name: "DashboardPage");
        ref.read(screenTimeDisplayProvider.notifier).refreshFromSource();
    });
  }

  @override
  void dispose() {
    developer.log("DashboardPage dispose: Removing WidgetsBindingObserver", name: "DashboardPage");
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    developer.log("DashboardPage didChangeAppLifecycleState: $state", name: "DashboardPage");
    if (state == AppLifecycleState.resumed) {
      // When app resumes, refresh screen time from Hive and inform native service
      developer.log("DashboardPage resumed: Calling refreshFromSource for screen time", name: "DashboardPage");
      ref.read(screenTimeDisplayProvider.notifier).refreshFromSource();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
  }

  @override
  Widget build(BuildContext context) {
    final String currentDate = DateFormat('EEE, MMM d, yyyy').format(DateTime.now());
    final tasksStream = ref.watch(tasksStreamProvider);
    final screenTimeAsyncValue = ref.watch(screenTimeDisplayProvider);

    // Attempt to send current schedule and blocked lists to background service
    // This should ideally be done when these settings change, or on service start.
    // Doing it on every build is not efficient but ensures service has latest data for now.
    // TODO: Move this to a more appropriate place (e.g., when settings are saved, or on app startup sequence after service start)
    _sendConfigToService(ref);


    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskTime Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.go('/settings');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentDate,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    'Screen Time Remaining:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  screenTimeAsyncValue.when(
                    data: (duration) => Text(
                      _formatDuration(duration),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    loading: () => Text(
                       _formatDuration(Duration(milliseconds: ref.read(earnedScreenTimeRepositoryProvider).getEarnedScreenTimeMs())), // Show last known from Hive
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).hintColor.withOpacity(0.7), // Indicate loading/potentially stale
                          ),
                    ),
                    error: (err, stack) => Tooltip(
                      message: err.toString(),
                      child: Text(
                        "Error", // Or display last known good value
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks for Today:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ToggleButtons(
                  isSelected: [
                    ref.watch(dashboardTaskViewProvider) == DashboardTaskView.list,
                    ref.watch(dashboardTaskViewProvider) == DashboardTaskView.matrix,
                  ],
                  onPressed: (index) {
                    ref.read(dashboardTaskViewProvider.notifier).state =
                        index == 0 ? DashboardTaskView.list : DashboardTaskView.matrix;
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  selectedBorderColor: Theme.of(context).colorScheme.primary,
                  selectedColor: Colors.white, // Text color when selected
                  fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  color: Theme.of(context).colorScheme.primary, // Text color when not selected
                  constraints: const BoxConstraints(minHeight: 36.0, minWidth: 48.0),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.list)),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.grid_view_outlined)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: tasksStream.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Center(child: Text('No tasks yet. Add one!'));
                  }
                  // Sort tasks: incomplete first, then by creation date descending for list view
                  final sortedTasks = List<TaskEntity>.from(tasks);
                  sortedTasks.sort((a, b) {
                    if (a.isCompleted != b.isCompleted) {
                      return a.isCompleted ? 1 : -1;
                    }
                    return b.createdAt.compareTo(a.createdAt);
                  });

                  final currentView = ref.watch(dashboardTaskViewProvider);
                  if (currentView == DashboardTaskView.list) {
                    return ListView.builder(
                      itemCount: sortedTasks.length,
                      itemBuilder: (context, index) {
                        final task = sortedTasks[index];
                        return TaskListTile(task: task);
                      },
                    );
                  } else {
                    // Use all tasks for the matrix view, filtering is done inside EisenhowerMatrixView
                    return EisenhowerMatrixView(tasks: tasks);
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text('Error loading tasks: ${error.toString()}'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.goNamed('task_form');
        },
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // Helper to send configuration to service.
  // TODO: This is not the ideal place; should be triggered on config change or app start.
  void _sendConfigToService(WidgetRef ref) {
    final scheduleState = ref.read(appBlockScheduleProvider);
    final blockedItemsState = ref.read(blockedItemsProvider);

    scheduleState.whenData((schedule) {
      blockedItemsState.whenData((blockedItems) {
        final scheduleForNative = schedule.scheduleDays.map((d) => {
          "dayOfWeek": d.dayOfWeek,
          "isEnabled": d.isEnabled,
          "startTime": d.startTime,
          "endTime": d.endTime,
        }).toList();

        final appPackages = blockedItems.apps.map((a) => a.packageName).toList();
        final websiteHosts = blockedItems.websites.map((w) => w.url).toList();

        // Fire and forget for now
        BackgroundServiceChannel.updateConfiguration(
          schedule: scheduleForNative,
          blockedAppPackages: appPackages,
          blockedWebsiteHosts: websiteHosts,
        ).then((result) {
          developer.log("Config update sent from dashboard (on build): $result", name: "DashboardPage");
        }).catchError((e) {
          developer.log("Error sending config from dashboard: $e", name: "DashboardPage", error: e);
        });
      });
    });
  }
}
