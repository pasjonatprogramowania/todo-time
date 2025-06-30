import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // For potential future use with task updates
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/presentation/widgets/task_list_tile.dart'; // Re-use for consistency, or a smaller version

class EisenhowerMatrixView extends StatelessWidget {
  final List<TaskEntity> tasks;

  const EisenhowerMatrixView({super.key, required this.tasks});

  List<TaskEntity> _filterTasks(TaskCategory category) {
    return tasks.where((task) => task.category == category && !task.isCompleted).toList()
      ..sort((a,b) => a.createdAt.compareTo(b.createdAt)); // Show oldest incomplete first in quadrants
  }

  @override
  Widget build(BuildContext context) {
    final urgentImportant = _filterTasks(TaskCategory.urgentImportant);
    final importantNotUrgent = _filterTasks(TaskCategory.importantNotUrgent);
    final urgentNotImportant = _filterTasks(TaskCategory.urgentNotImportant);
    final notUrgentNotImportant = _filterTasks(TaskCategory.notUrgentNotImportant);

    // Define accent colors for quadrants as per spec (section 3.2)
    final Color urgentImportantColor = Colors.red.shade700;
    final Color importantNotUrgentColor = Colors.orange.shade700;
    final Color urgentNotImportantColor = Colors.blue.shade700;
    final Color notUrgentNotImportantColor = Colors.grey.shade700;


    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 0.85, // Adjust for content, might need to be smaller if TaskListTile is too big
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: <Widget>[
          _QuadrantView(title: 'Urgent & Important', tasks: urgentImportant, headerColor: urgentImportantColor, subTitle: '(Do First)'),
          _QuadrantView(title: 'Important, Not Urgent', tasks: importantNotUrgent, headerColor: importantNotUrgentColor, subTitle: '(Schedule)'),
          _QuadrantView(title: 'Urgent, Not Important', tasks: urgentNotImportant, headerColor: urgentNotImportantColor, subTitle: '(Delegate)'),
          _QuadrantView(title: 'Not Urgent & Not Important', tasks: notUrgentNotImportant, headerColor: notUrgentNotImportantColor, subTitle: '(Eliminate)'),
        ],
      ),
    );
  }
}

class _QuadrantView extends StatelessWidget {
  final String title;
  final String subTitle;
  final List<TaskEntity> tasks;
  final Color headerColor;

  const _QuadrantView({
    required this.title,
    required this.subTitle,
    required this.tasks,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: headerColor.withOpacity(0.7), width: 1.5)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: headerColor.withOpacity(isDark ? 0.5 : 0.25),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : headerColor),
                  textAlign: TextAlign.center,
                ),
                 Text(
                  subTitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDark ? Colors.grey.shade300 : headerColor.withOpacity(0.9)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('No tasks in this quadrant.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center,),
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.all(6),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      // Using a more compact tile for matrix view
                      return _CompactTaskTile(task: tasks[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// A more compact version of TaskListTile for the matrix
class _CompactTaskTile extends ConsumerWidget {
  final TaskEntity task;
  const _CompactTaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     final bool isDark = Theme.of(context).brightness == Brightness.dark;
     final Color completedIconColor = task.isCompleted
        ? Theme.of(context).colorScheme.primary
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 2.0),
      child: InkWell(
        onTap: () => GoRouter.of(context).goNamed('task_form', extra: task),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
          child: Row(
            children: [
               GestureDetector(
                 onTap: () async {
                    final wasCompleted = task.isCompleted;
                    await ref.read(toggleTaskStatusUseCaseProvider).call(task.id);
                    if (!wasCompleted) {
                      await ref.read(earnedScreenTimeRepositoryProvider).addScreenTime(task.timeAward);
                    }
                 },
                 child: Icon(
                  task.isCompleted ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                  size: 20,
                  color: completedIconColor,
                ),
               ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  task.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        fontSize: 13,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "+${task.timeAward.inMinutes}m",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
