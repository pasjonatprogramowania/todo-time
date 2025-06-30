import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/presentation/providers/task_usecase_providers.dart';
import 'package:task_time/presentation/widgets/task_list_tile.dart'; // Import the new widget

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m ${twoDigitSeconds}s";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String currentDate = DateFormat('EEE, MMM d, yyyy').format(DateTime.now());
    final tasksStream = ref.watch(tasksStreamProvider);
    // Placeholder for screen time - will be managed by a provider later
    final Duration screenTimeRemaining = Duration.zero;


    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskTime Dashboard'), // Placeholder
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
                  Text(
                    _formatDuration(screenTimeRemaining), // Placeholder
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // TODO: Add Task List / Eisenhower Matrix toggle here
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks for Today:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                // TODO: Add toggle buttons for List/Matrix view
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: tasksStream.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Center(child: Text('No tasks yet. Add one!'));
                  }
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskListTile(task: task);
                    },
                  );
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
          context.goNamed('task_form'); // Navigate to add task screen
        },
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
